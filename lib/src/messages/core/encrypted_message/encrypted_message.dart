import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/src/did_resolver_manager.dart';
import 'package:didcomm/src/errors/missing_authentication_tag_error.dart';
import 'package:didcomm/src/errors/missing_initialization_vector_error.dart';
import 'package:didcomm/src/errors/missing_key_agreement_error.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:json_annotation/json_annotation.dart';
import 'package:ssi/ssi.dart' hide Jwk;

import '../../../../didcomm.dart';
import '../../../annotations/own_json_properties.dart';
import '../../../common/crypto.dart';
import '../../../converters/base64_url_converter.dart';
import '../../../converters/jwe_header_converter.dart';
import '../../../ecdh/ecdh.dart';
import '../../../errors/missing_authentication_tag_error.dart';
import '../../../errors/missing_initialization_vector_error.dart';
import '../../../errors/missing_key_agreement_error.dart';
import '../../../extensions/extensions.dart';
import '../../../jwks/jwk.dart';
import '../../jwm.dart';

part 'encrypted_message.g.dart';
part 'encrypted_message.own_json_props.g.dart';

/// Represents a DIDComm v2 Encrypted Message as defined in the DIDComm Messaging specification.
///
/// See: https://identity.foundation/didcomm-messaging/spec/#didcomm-encrypted-messages
@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class EncryptedMessage extends DidcommMessage {
  /// The default media type for encrypted DIDComm messages as per the spec.
  static final mediaType = 'application/didcomm-encrypted+json';

  /// The ciphertext of the encrypted message.
  @JsonKey(name: 'ciphertext')
  @Base64UrlConverter()
  final Uint8List cipherText;

  /// The base64Url-encoded JWE protected header. Use JweHeaderConverter to convert to [JweHeader] if needed.
  /// This is kept as a raw string for decryption integrity. Converting with JweHeaderConverter during deserialization
  /// might cause decryption issues later, when message is unpacked.
  final String protected;

  /// List of recipients, each with their own encrypted key and header.
  final List<Recipient> recipients;

  /// The authentication tag for AEAD encryption ("tag" field in DIDComm spec).
  @JsonKey(name: 'tag')
  @Base64UrlConverter()
  final Uint8List authenticationTag;

  /// The initialization vector for AEAD encryption ("iv" field in DIDComm spec).
  @JsonKey(name: 'iv')
  @Base64UrlConverter()
  final Uint8List initializationVector;

  static const _jweHeaderConverter = JweHeaderConverter();

  /// Constructs an [EncryptedMessage].
  ///
  /// [cipherText]: The encrypted inner DIDComm message.
  /// [protected]: The base64Url-encoded JWE protected header.
  /// [recipients]: List of recipients.
  /// [authenticationTag]: The authentication tag for AEAD encryption.
  /// [initializationVector]: The initialization vector for AEAD encryption.
  EncryptedMessage({
    required this.cipherText,
    required this.protected,
    required this.recipients,
    required this.authenticationTag,
    required this.initializationVector,
  });

  /// Packs a [DidcommMessage] into an [EncryptedMessage] using anonymous encryption (ECDH-ES).
  ///
  /// [message]: The message to encrypt.
  /// [keyPair]: The sender's key pair.
  /// [recipientDidDocuments]: List of recipient's DID documents.
  /// [encryptionAlgorithm]: Algorithm for content encryption.
  ///
  /// Returns an [EncryptedMessage].
  static Future<EncryptedMessage> packAnonymously(
    DidcommMessage message, {
    required KeyPair keyPair,
    required List<DidDocument> recipientDidDocuments,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    return await EncryptedMessage.pack(
      message,
      keyPair: keyPair,
      recipientDidDocuments: recipientDidDocuments,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  /// Packs a [DidcommMessage] into an [EncryptedMessage] using authenticated encryption (ECDH-1PU).
  ///
  /// [message]: The message to encrypt.
  /// [keyPair]: The sender's key pair.
  /// [didKeyId]: The sender's key ID.
  /// [recipientDidDocuments]: List of recipient's DID documents.
  /// [encryptionAlgorithm]: Algorithm for content encryption.
  ///
  /// Returns an [EncryptedMessage].
  static Future<EncryptedMessage> packWithAuthentication(
    DidcommMessage message, {
    required KeyPair keyPair,
    required String didKeyId,
    required List<DidDocument> recipientDidDocuments,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    return await EncryptedMessage.pack(
      message,
      keyPair: keyPair,
      didKeyId: didKeyId,
      recipientDidDocuments: recipientDidDocuments,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  /// Packs a [DidcommMessage] into an [EncryptedMessage] using the provided cryptographic parameters.
  ///
  /// [message]: The message to encrypt.
  /// [keyPair]: The sender's key pair.
  /// [didKeyId]: The sender's key ID (optional).
  /// [recipientDidDocuments]: List of recipient's DID Documents.
  /// [keyWrappingAlgorithm]: Algorithm for key wrapping.
  /// [encryptionAlgorithm]: Algorithm for content encryption.
  ///
  /// Returns an [EncryptedMessage].
  static Future<EncryptedMessage> pack(
    DidcommMessage message, {
    required KeyPair keyPair,
    String? didKeyId,
    required List<DidDocument> recipientDidDocuments,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    final publicKey = keyPair.publicKey;
    final ephemeralKeyPair = generateEphemeralKeyPair(publicKey.type);

    final jweHeader = await JweHeader.fromKeyPair(
      keyPair,
      subjectKeyId: didKeyId,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
      recipientDidDocuments: recipientDidDocuments,
      ephemeralPrivateKeyBytes: ephemeralKeyPair.privateKeyBytes,
      ephemeralPublicKeyBytes: ephemeralKeyPair.publicKeyBytes,
    );

    final protected = _jweHeaderConverter.toJson(jweHeader);

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
        'Initialization vector not set after encryption',
      );
    }

    if (encryptedInnerMessage.authenticationTag == null) {
      throw MissingAuthenticationTag(
        'Authentication tag not set after encryption',
      );
    }

    final recipients = await _createRecipients(
      keyPair: keyPair,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      recipientDidDocuments: recipientDidDocuments,
      authenticationTag: encryptedInnerMessage.authenticationTag!,
      contentEncryptionKey: contentEncryptionKey,
      ephemeralPrivateKeyBytes: ephemeralKeyPair.privateKeyBytes,
      jweHeader: jweHeader,
    );

    final encryptedMessage = EncryptedMessage(
      cipherText: encryptedInnerMessage.data,
      protected: protected,
      recipients: recipients,
      authenticationTag: encryptedInnerMessage.authenticationTag!,
      initializationVector: encryptedInnerMessage.initializationVector!,
    );

    return encryptedMessage;
  }

  /// Unpacks and decrypts the encrypted message, returning the inner message as a JSON map.
  /// Unlike [DidcommMessage.unpackToPlainTextMessage], this method does not recursively unpack nested messages,
  /// but returns the top most message from the ciphertext.
  ///
  /// [recipientWallet]: The wallet to use for decryption.
  ///
  /// Returns the decrypted inner message as a JSON map.
  Future<Map<String, dynamic>> unpack({required Wallet recipientWallet}) async {
    final self = await _findSelfAsRecipient(recipientWallet);
    final jweHeader = _jweHeaderConverter.fromJson(protected);

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
        additionalAuthenticatedData: ascii.encode(protected),
      ),
    );

    final innerMessage = jsonDecode(utf8.decode(decrypted));
    return innerMessage as Map<String, dynamic>;
  }

  Future<Jwk> _getSenderJwk(String subjectKeyId) async {
    final senderDid = subjectKeyId.split('#').first;
    final senderDidDocument = await DidResolverManager.resolve(senderDid);

    final keyAgreement = senderDidDocument.keyAgreement.firstWhere(
      (keyAgreement) => keyAgreement.id == subjectKeyId,
      orElse: () => throw MissingKeyAgreementError(
        'Can not find a key agreement for subject ID',
      ),
    );

    final senderJwk = Jwk.fromJson(keyAgreement.asJwk().toJson());

    return senderJwk;
  }

  Future<Recipient> _findSelfAsRecipient(Wallet wallet) async {
    final self = recipients.firstWhere(
      (recipient) => wallet.getKeyIdByDidKeyId(recipient.header.keyId) != null,
      orElse: () => throw Exception('Self recipient not found'),
    );

    return self;
  }

  /// Checks if the given [message] map is an encrypted message by verifying required properties.
  static bool isEncryptedMessage(Map<String, dynamic> message) {
    return _$ownJsonProperties.every((prop) => message.containsKey(prop));
  }

  /// Creates an [EncryptedMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the encrypted message.
  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    final message = _$EncryptedMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  /// Serializes the encrypted message to a JSON map, including custom headers.
  @override
  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$EncryptedMessageToJson(this));

  /// Creates a new symmetric content encryption key for the given [encryptionAlgorithm].
  static ck.SymmetricKey _createContentEncryptionKey(
    EncryptionAlgorithm encryptionAlgorithm,
  ) {
    // TODO: clarify why 512 for a256cbc
    final keySize = encryptionAlgorithm == EncryptionAlgorithm.a256cbc
        ? 512
        : 256;
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
    required KeyPair keyPair,
    required List<DidDocument> recipientDidDocuments,
    required JweHeader jweHeader,
    required ck.SymmetricKey contentEncryptionKey,
    required Uint8List ephemeralPrivateKeyBytes,
    required Uint8List authenticationTag,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
  }) async {
    final publicKey = keyPair.publicKey;

    final futures = recipientDidDocuments.map((didDocument) async {
      final curve = publicKey.type.asEncryptionCapableCurve();
      final keyAgreement = didDocument.keyAgreement.firstWithCurve(curve);

      final encryptedKey = await Ecdh.encrypt(
        contentEncryptionKey.keyValue,
        senderKeyPair: keyPair,
        recipientJwk: keyAgreement.toJwk(),
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        jweHeader: jweHeader,
        authenticationTag: authenticationTag,
      );

      return Recipient(
        header: RecipientHeader(keyId: keyAgreement.id),
        encryptedKey: encryptedKey,
      );
    });

    return Future.wait(futures);
  }
}
