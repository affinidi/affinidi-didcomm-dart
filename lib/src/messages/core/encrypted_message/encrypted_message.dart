import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/src/errors/missing_authentication_tag_error.dart';
import 'package:didcomm/src/errors/missing_initialization_vector_error.dart';
import 'package:didcomm/src/errors/missing_key_agreement_error.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:ssi/ssi.dart' hide Jwk;

import '../../../converters/base64_url_converter.dart';
import '../../../converters/jwe_header_converter.dart';
import '../../../ecdh/ecdh.dart';
import '../../../jwks/jwks.dart';
import '../../../annotations/own_json_properties.dart';
import '../../../common/crypto.dart';
import '../../../extensions/extensions.dart';
import '../../algorithm_types/algorithms_types.dart';
import '../../didcomm_message.dart';
import '../../jwm.dart';
import 'recipients/recipient.dart';
import 'recipients/recipient_header.dart';

part 'encrypted_message.g.dart';
part 'encrypted_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false)
class EncryptedMessage extends DidcommMessage {
  static final mediaType = 'application/didcomm-encrypted+json';

  @JsonKey(name: 'ciphertext')
  @Base64UrlConverter()
  final Uint8List cipherText;

  // this is base64Url encoded JWE Header.
  // we can't use JweHeaderConverter annotation here,
  // because raw protected field is needed for decryption (additionalAuthenticatedData).
  // if during serialization/deserialization it looses or gains some fields,
  // decryption fails.
  // this is why it is important to keep the original value from JSON
  final String protected;

  final List<Recipient> recipients;

  @JsonKey(name: 'tag')
  @Base64UrlConverter()
  final Uint8List authenticationTag;

  @JsonKey(name: 'iv')
  @Base64UrlConverter()
  final Uint8List initializationVector;

  EncryptedMessage({
    required this.cipherText,
    required this.protected,
    required this.recipients,
    required this.authenticationTag,
    required this.initializationVector,
  });

  static Future<EncryptedMessage> packAnonymously(
    DidcommMessage message, {
    required Wallet wallet,
    required String keyId,
    required List<Jwks> jwksPerRecipient,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    return await EncryptedMessage.pack(
      message,
      wallet: wallet,
      keyId: keyId,
      jwksPerRecipient: jwksPerRecipient,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  static Future<EncryptedMessage> packWithAuthentication(
    DidcommMessage message, {
    required Wallet wallet,
    required String keyId,
    required List<Jwks> jwksPerRecipient,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    return await EncryptedMessage.pack(
      message,
      wallet: wallet,
      keyId: keyId,
      jwksPerRecipient: jwksPerRecipient,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  static Future<EncryptedMessage> pack(
    DidcommMessage message, {
    required Wallet wallet,
    required String keyId,
    required List<Jwks> jwksPerRecipient,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    // if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
    //   final plainTextMessage = DidcommMessage.unpackPlainTextMessage(
    //     message: message,
    //     wallet: wallet,
    //   );

    //   if (plainTextMessage.from == null) {
    //     throw ArgumentError(
    //       'authcrypt envelope requires from header to be set in the plaintext message',
    //       'message',
    //     );
    //   }
    // }

    final publicKey = await wallet.getPublicKey(keyId);
    final ephemeralKeyPair = generateEphemeralKeyPair(publicKey.type);

    final jweHeader = await JweHeader.fromWalletKey(
      wallet,
      keyId,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
      jwksPerRecipient: jwksPerRecipient,
      ephemeralPrivateKeyBytes: ephemeralKeyPair.privateKeyBytes,
      ephemeralPublicKeyBytes: ephemeralKeyPair.publicKeyBytes,
    );

    final protected = JweHeaderConverter().toJson(jweHeader);

    final contentEncryptionKey = _createContentEncryptionKey(
      encryptionAlgorithm,
    );

    final encryptedInnerMessage = _encryptMessage(
      message,
      encryptionKey: contentEncryptionKey,
      encryptionAlgorithm: encryptionAlgorithm,
      protected: protected,
    );

    if (encryptedInnerMessage.initializationVector == null) {
      throw MissingInitializationVectorError(
          'Initialization vector not set after encryption');
    }

    if (encryptedInnerMessage.authenticationTag == null) {
      throw MissingAuthenticationTag(
          'Authentication tag not set after encryption');
    }

    final recipients = await _createRecipients(
      wallet: wallet,
      keyId: keyId,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      jwksPerRecipient: jwksPerRecipient,
      authenticationTag: encryptedInnerMessage.authenticationTag!,
      contentEncryptionKey: contentEncryptionKey,
      ephemeralPrivateKeyBytes: ephemeralKeyPair.privateKeyBytes,
      jweHeader: jweHeader,
    );

    return EncryptedMessage(
      cipherText: encryptedInnerMessage.data,
      protected: protected,
      recipients: recipients,
      authenticationTag: encryptedInnerMessage.authenticationTag!,
      initializationVector: encryptedInnerMessage.initializationVector!,
    );
  }

  Future<Map<String, dynamic>> unpack({required Wallet recipientWallet}) async {
    final self = await _findSelfAsRecipient(recipientWallet);
    final jweHeader = JweHeaderConverter().fromJson(protected);

    final subjectKeyId = jweHeader.subjectKeyId;

    if (subjectKeyId == null &&
        jweHeader.keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      throw ArgumentError(
        'skid is required for ${KeyWrappingAlgorithm.ecdh1Pu.value}',
      );
    }

    final contentEncryptionKey = await Ecdh.decrypt(
      self.encryptedKey,
      recipientWallet: recipientWallet,
      jweHeader: jweHeader,
      senderJwk: jweHeader.keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu
          ? await _getSenderJwk(subjectKeyId!)
          : null,
      self: self,
      authenticationTag: authenticationTag,
    );

    final encrypter = createSymmetricEncrypter(
      jweHeader.encryptionAlgorithm,
      ck.SymmetricKey(keyValue: contentEncryptionKey),
    );

    final decrypted = encrypter.decrypt(
      ck.EncryptionResult(
        cipherText,
        initializationVector: initializationVector,
        authenticationTag: authenticationTag,
        additionalAuthenticatedData: ascii.encode(
          protected,
        ),
      ),
    );

    return jsonDecode(utf8.decode(decrypted));
  }

  Future<Jwk> _getSenderJwk(String subjectKeyId) async {
    final senderDid = subjectKeyId.split('#').first;
    final senderDidDocument = await UniversalDIDResolver.resolve(senderDid);

    final keyAgreement = senderDidDocument.keyAgreement.firstWhere(
      (keyAgreement) => keyAgreement.id == subjectKeyId,
      orElse: () => throw MissingKeyAgreementError(
          'Can not find a key agreement for subject ID'),
    );

    final senderJwk = Jwk.fromJson(
      keyAgreement.asJwk().toJson(),
    );

    return senderJwk;
  }

  Future<Recipient> _findSelfAsRecipient(Wallet wallet) async {
    final self = recipients.firstWhere(
      (recipient) => wallet.getKeyIdByJwkId(recipient.header.keyId) != null,
      orElse: () => throw Exception('Self recipient not found'),
    );

    return self;
  }

  static bool isEncryptedMessage(Map<String, dynamic> message) {
    return _$ownJsonProperties.every((prop) => message.containsKey(prop));
  }

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    final message = _$EncryptedMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$EncryptedMessageToJson(this));

  static ck.SymmetricKey _createContentEncryptionKey(
    EncryptionAlgorithm encryptionAlgorithm,
  ) {
    // TODO: clarify why 512 for a256cbc
    final keySize =
        encryptionAlgorithm == EncryptionAlgorithm.a256cbc ? 512 : 256;
    return ck.SymmetricKey.generate(keySize);
  }

  static ck.EncryptionResult _encryptMessage(
    DidcommMessage message, {
    required ck.SymmetricKey encryptionKey,
    required EncryptionAlgorithm encryptionAlgorithm,
    required String protected,
  }) {
    final encrypter = createSymmetricEncrypter(
      encryptionAlgorithm,
      encryptionKey,
    );

    final headerBytes = ascii.encode(protected);

    return encrypter.encrypt(
      message.toJsonBytes(),
      additionalAuthenticatedData: headerBytes,
    );
  }

  static Future<List<Recipient>> _createRecipients({
    required Wallet wallet,
    required String keyId,
    required List<Jwks> jwksPerRecipient,
    required JweHeader jweHeader,
    required ck.SymmetricKey contentEncryptionKey,
    required Uint8List ephemeralPrivateKeyBytes,
    required Uint8List authenticationTag,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
  }) async {
    final publicKey = await wallet.getPublicKey(keyId);

    final futures = jwksPerRecipient.map((jwks) async {
      final curve = publicKey.type.asDidcommCompatibleCurve();
      final recipientJwk = jwks.firstWithCurve(curve);

      final encryptedKey = await Ecdh.encrypt(
        contentEncryptionKey.keyValue,
        senderWallet: wallet,
        senderKeyId: keyId,
        recipientJwk: recipientJwk,
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        jweHeader: jweHeader,
        authenticationTag: authenticationTag,
      );

      return Recipient(
        header: RecipientHeader(keyId: recipientJwk.keyId!),
        encryptedKey: encryptedKey,
      );
    });

    return Future.wait(futures);
  }
}
