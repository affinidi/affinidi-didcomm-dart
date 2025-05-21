import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:ssi/ssi.dart';
import '../../converters/base64_url_converter.dart';
import '../../converters/jwe_header_converter.dart';
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

  static Future<EncryptedMessage> pack(
    DidcommMessage message, {
    required Wallet wallet,
    required String keyId,
    required List<Jwks> jwksPerRecipient,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1PU) {
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

    final recipients = await _encryptContentEncryptionKey(
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

  static Future<List<Recipient>> _encryptContentEncryptionKey({
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
        header: RecipientHeader(keyId: jwk.keyId),
        encryptedKey: await encryptAsymmetricWithWalletKey(
          contentEncryptionKey.keyValue,
          wallet: wallet,
          keyId: keyId,
          recipientPublicKeyJwk: jwk.toJson(),
          keyWrappingAlgorithm: keyWrappingAlgorithm,
          ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
          jweHeader: jweHeader,
        ),
      );
    });

    return Future.wait(futures);
  }
}
