import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:ssi/ssi.dart';
import '../../jwks/jwks.dart';
import '../../annotations/own_json_properties.dart';
import '../../common/crypto.dart';
import '../../common/encoding.dart';
import '../../errors/errors.dart';
import '../../extensions/extensions.dart';
import '../algorithm_types/algorithms_types.dart';
import '../didcomm_message.dart';
import '../jwm/jwe_header.dart';
import '../recipients/recipient.dart';

part 'encrypted_message.g.dart';
part 'encrypted_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false)
class EncryptedMessage extends DidcommMessage {
  @override
  String get mediaType => 'application/didcomm-encrypted+json';

  @JsonKey(name: 'ciphertext')
  final String cipherText;

  final String protected;
  final List<Recipient> recipients;
  final String tag;

  @JsonKey(name: 'iv')
  final String initializationVector;

  EncryptedMessage({
    required this.cipherText,
    required this.protected,
    required this.recipients,
    required this.tag,
    required this.initializationVector,
  });

  static Future<EncryptedMessage> wrapMessage(
    DidcommMessage message, {
    required Wallet wallet,
    required String keyId,
    required Jwks recipientJwks,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1PU) {
      final plainTextMessage = DidcommMessage.extractPlainTextMessage(
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
    final ephemeralKeyPair = getEphemeralKeyPair(publicKey.type);

    final jweHeader = await JweHeader.fromWalletKey(
      wallet,
      keyId,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
      recipientJwks: recipientJwks,
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

    return EncryptedMessage(
      cipherText: '',
      protected: '',
      recipients: [],
      tag: '',
      initializationVector: '',
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
    if (encryptionAlgorithm == EncryptionAlgorithm.a256cbc) {
      // TODO: clarify why 512
      return ck.SymmetricKey.generate(512);
    }

    return ck.SymmetricKey.generate(256);
  }

  static ck.EncryptionResult _encryptMessage(
    DidcommMessage message, {
    required ck.SymmetricKey encryptionKey,
    required EncryptionAlgorithm encryptionAlgorithm,
    required JweHeader jweHeader,
  }) {
    final encrypter = _createEncrypter(encryptionAlgorithm, encryptionKey);

    final headerBase64Url = base64UrlEncodeNoPadding(jweHeader.toJsonBytes());
    final headerBytes = ascii.encode(headerBase64Url);

    return encrypter.encrypt(
      message.toJsonBytes(),
      additionalAuthenticatedData: headerBytes,
    );
  }

  static ck.Encrypter _createEncrypter(
    EncryptionAlgorithm encryptionAlgorithm,
    ck.SymmetricKey encryptionKey,
  ) {
    if (encryptionAlgorithm == EncryptionAlgorithm.a256cbc) {
      return encryptionKey.createEncrypter(
        ck.algorithms.encryption.aes.cbcWithHmac.sha512,
      );
    }

    if (encryptionAlgorithm == EncryptionAlgorithm.a256gcm) {
      return encryptionKey.createEncrypter(ck.algorithms.encryption.aes.gcm);
    }

    throw UnsupportedEncryptionAlgorithmError(encryptionAlgorithm);
  }
}
