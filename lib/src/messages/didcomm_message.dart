import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:meta/meta.dart';

class DidcommMessage {
  DidcommMessage();

  static final mediaType = 'application/didcomm-plain+json';
  final Map<String, dynamic> _customHeaders = {};

  dynamic operator [](String key) => _customHeaders[key];
  void operator []=(String key, dynamic value) => _customHeaders[key] = value;

  static Future<SignedMessage> packIntoSignedMessage(
    DidcommMessage message, {
    required DidSigner signer,
  }) async {
    return await SignedMessage.pack(message, signer: signer);
  }

  static Future<EncryptedMessage> packIntoEncryptedMessage(
    DidcommMessage message, {
    required KeyPair keyPair,
    required String keyPairJwkId,
    required List<Jwks> jwksPerRecipient,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    return await EncryptedMessage.pack(
      message,
      keyPair: keyPair,
      keyPairJwkId: keyPairJwkId,
      jwksPerRecipient: jwksPerRecipient,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  static Future<EncryptedMessage> packIntoSignedAndEncryptedMessages(
    DidcommMessage message, {
    required KeyPair keyPair,
    required String keyPairJwkId,
    required List<Jwks> jwksPerRecipient,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
    required DidSigner signer,
  }) async {
    final signedMessage = await SignedMessage.pack(
      message,
      signer: signer,
    );

    return await EncryptedMessage.pack(
      signedMessage,
      keyPair: keyPair,
      keyPairJwkId: keyPairJwkId,
      jwksPerRecipient: jwksPerRecipient,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  static Future<PlainTextMessage?> unpackToPlainTextMessage({
    required Map<String, dynamic> message,
    required Wallet recipientWallet,
  }) async {
    // TODO: add recursiv check for cases when there multiple encryption or signed leyars
    var currentMessage = message;

    if (EncryptedMessage.isEncryptedMessage(currentMessage)) {
      final encryptedMessage = EncryptedMessage.fromJson(currentMessage);
      currentMessage = await encryptedMessage.unpack(
        recipientWallet: recipientWallet,
      );
    }

    if (SignedMessage.isSignedMessage(currentMessage)) {
      final signedMessage = SignedMessage.fromJson(currentMessage);
      currentMessage = await signedMessage.unpack();
    }

    return PlainTextMessage.fromJson(currentMessage);
  }

  static Future<SignedMessage?> unpackToSignedMessage({
    required Map<String, dynamic> message,
    required Wallet recipientWallet,
  }) async {
    // TODO: add recursiv check for cases when there multiple encryption or signed leyars
    var currentMessage = message;

    if (EncryptedMessage.isEncryptedMessage(currentMessage)) {
      final encryptedMessage = EncryptedMessage.fromJson(currentMessage);
      currentMessage = await encryptedMessage.unpack(
        recipientWallet: recipientWallet,
      );
    }

    if (SignedMessage.isSignedMessage(currentMessage)) {
      return SignedMessage.fromJson(currentMessage);
    }

    return null;
  }

  @protected
  Map<String, dynamic> withCustomHeaders(Map<String, dynamic> json) {
    return {...json, ..._customHeaders};
  }

  @protected
  void assignCustomHeaders(Map<String, dynamic> json, List<String> ownHeaders) {
    final customHeaders = json.keys.where((key) => !ownHeaders.contains(key));

    for (final key in customHeaders) {
      this[key] = json[key];
    }
  }
}
