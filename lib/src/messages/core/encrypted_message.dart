import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/ecdh/ecdh_1pu/ecdh_1pu_for_secp256_and_p.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:ssi/ssi.dart' hide Jwk;

import '../../converters/base64_url_converter.dart';
import '../../converters/jwe_header_converter.dart';
import '../../ecdh/ecdh.dart';
import '../../jwks/jwks.dart';
import '../../annotations/own_json_properties.dart';
import '../../common/crypto.dart';
import '../../common/encoding.dart';
import '../../extensions/extensions.dart';
import '../algorithm_types/algorithms_types.dart';
import '../didcomm_message.dart';
import '../jwm/jwe_header.dart';
import '../recipients/recipient.dart';
import '../recipients/recipient_header.dart';

part 'encrypted_message.g.dart';
part 'encrypted_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false)
class EncryptedMessage extends DidcommMessage {
  @override
  String get mediaType => 'application/didcomm-encrypted+json';

  @JsonKey(name: 'ciphertext')
  @Base64UrlConverter()
  final Uint8List cipherText;

  @JweHeaderConverter()
  final JweHeader protected;

  final List<Recipient> recipients;

  @Base64UrlConverter()
  final Uint8List tag;

  @JsonKey(name: 'iv')
  @Base64UrlConverter()
  final Uint8List initializationVector;

  EncryptedMessage({
    required this.cipherText,
    required this.protected,
    required this.recipients,
    required this.tag,
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
    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      final plainTextMessage = DidcommMessage.unpackPlainTextMessage(
        message: message,
        wallet: wallet,
      );

      if (plainTextMessage.from == null) {
        throw ArgumentError(
          'authcrypt envelope requires from header to be set in the plaintext message',
          'message',
        );
      }
    }

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

    final contentEncryptionKey = _createContentEncryptionKey(
      encryptionAlgorithm,
    );

    final encryptedInnerMessage = _encryptMessage(
      message,
      encryptionKey: contentEncryptionKey,
      encryptionAlgorithm: encryptionAlgorithm,
      jweHeader: jweHeader,
    );

    if (encryptedInnerMessage.initializationVector == null) {
      throw Exception('Initialization vector not set after encryption');
    }

    if (encryptedInnerMessage.authenticationTag == null) {
      throw Exception('Authentication tag not set after encryption');
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
      protected: jweHeader,
      recipients: recipients,
      tag: encryptedInnerMessage.authenticationTag!,
      initializationVector: encryptedInnerMessage.initializationVector!,
    );
  }

  static Future<DidcommMessage> unpack(
    EncryptedMessage message, {
    required Wallet wallet,
  }) async {
    final self = await _findSelfAsRecipient(message, wallet);

    final senderKeyId = message.protected.resolveSubjectKeyId();
    final senderDidDocument = await UniversalDIDResolver.resolve(
      senderKeyId.split('#').first,
    );

    final senderJwk = Jwk.fromJson(
      senderDidDocument.keyAgreement.first.asJwk().toJson(),
    );

    // TODO: use Ecdh class instead
    final a = Ecdh1PuForSecp256AndP(
      jweHeader: message.protected,
      authenticationTag: message.tag,
      publicKey1:
          Jwk.fromJson(
            message.protected.ephemeralKey.toJson(),
          ).toPublicKeyFromPoint(),
      publicKey2: senderJwk.toPublicKeyFromPoint(),
    );

    final contentEncryptionKey = await a.decryptData(
      data: self.encryptedKey,
      wallet: wallet,
      keyId: self.header.keyId.split('#').last,
    );
    // final contentEncryptionKey = await Ecdh.decrypt(
    //   self.encryptedKey,
    //   wallet: wallet,
    //   keyId: self.header.keyId,
    //   // FIXME
    //   jwk: Jwk.fromJson(message.protected.ephemeralKey.toJson()),
    //   authenticationTag: message.tag,
    //   jweHeader: message.protected,
    // );

    final encrypter = createSymmetricEncrypter(
      message.protected.encryptionAlgorithm,
      ck.SymmetricKey(keyValue: contentEncryptionKey),
    );

    final decrypted = encrypter.decrypt(
      ck.EncryptionResult(
        message.cipherText,
        initializationVector: message.initializationVector,
        authenticationTag: message.tag,
        additionalAuthenticatedData: ascii.encode(
          base64UrlEncodeNoPadding(message.protected.toJsonBytes()),
        ),
      ),
    );

    final json = jsonDecode(utf8.decode(decrypted));
    return PlaintextMessage.fromJson(json);
  }

  static Future<Recipient> _findSelfAsRecipient(
    EncryptedMessage message,
    Wallet wallet,
  ) async {
    for (final recipient in message.recipients) {
      final String? did;
      final String keyId;

      // TODO: make a reusable method for this
      if (recipient.header.keyId.contains('#')) {
        final parts = recipient.header.keyId.split('#');
        did = parts[0];
        keyId = parts[1];
      } else {
        did = null;
        keyId = recipient.header.keyId;
      }

      if (await wallet.hasKey(keyId)) {
        if (did != null) {
          final publicKey = await wallet.getPublicKey(keyId);
          final didDocument = DidKey.generateDocument(publicKey);

          if (didDocument.id != did) {
            continue;
          }
        }

        return recipient;
      }
    }

    throw Exception('No matching recipient found in the message');
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
    required JweHeader jweHeader,
  }) {
    final encrypter = createSymmetricEncrypter(
      encryptionAlgorithm,
      encryptionKey,
    );

    final headerBase64Url = base64UrlEncodeNoPadding(jweHeader.toJsonBytes());
    final headerBytes = ascii.encode(headerBase64Url);

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
      final jwk = jwks.firstWithCurve(curve);

      return Recipient(
        header: RecipientHeader(keyId: jwk.keyId!),
        encryptedKey: await Ecdh.encrypt(
          contentEncryptionKey.keyValue,
          wallet: wallet,
          keyId: keyId,
          jwk: jwk,
          ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
          jweHeader: jweHeader,
          authenticationTag: authenticationTag,
        ),
      );
    });

    return Future.wait(futures);
  }
}
