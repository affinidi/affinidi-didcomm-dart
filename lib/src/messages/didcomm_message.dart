import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:meta/meta.dart';

abstract class DidcommMessage {
  DidcommMessage();

  static final mediaType = 'application/didcomm-plain+json';
  final Map<String, dynamic> _customHeaders = {};

  dynamic operator [](String key) => _customHeaders[key];
  void operator []=(String key, dynamic value) => _customHeaders[key] = value;

  static Future<SignedMessage> packIntoSignedMessage(
    PlainTextMessage message, {
    required DidSigner signer,
  }) async {
    return await SignedMessage.pack(
      message,
      signer: signer,
    );
  }

  static Future<EncryptedMessage> packIntoEncryptedMessage(
    DidcommMessage message, {
    required KeyPair keyPair,
    required String didKeyId,
    required List<DidDocument> recipientDidDocuments,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    return await EncryptedMessage.pack(
      message,
      keyPair: keyPair,
      didKeyId: didKeyId,
      recipientDidDocuments: recipientDidDocuments,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  static Future<EncryptedMessage> packIntoSignedAndEncryptedMessages(
    PlainTextMessage message, {
    required KeyPair keyPair,
    required String didKeyId,
    required List<DidDocument> recipientDidDocuments,
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
      didKeyId: didKeyId,
      recipientDidDocuments: recipientDidDocuments,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  static Future<PlainTextMessage> unpackToPlainTextMessage({
    required Map<String, dynamic> message,
    required Wallet recipientWallet,
    bool validateAddressingConsistency = true,
  }) async {
    final (_, plaintextMessage) = await _unpack(
      messageTypeToStopUnpacking: PlainTextMessage,
      message: message,
      recipientWallet: recipientWallet,
      validateAddressingConsistency: validateAddressingConsistency,
    );

    if (plaintextMessage == null) {
      throw ArgumentError(
        'Failed to find Plain Text Message during unpacking',
        'message',
      );
    }

    return plaintextMessage;
  }

  static Future<SignedMessage> unpackToSignedMessage({
    required Map<String, dynamic> message,
    required Wallet recipientWallet,
    bool validateAddressingConsistency = true,
  }) async {
    final (signedMessage, _) = await _unpack(
      messageTypeToStopUnpacking: SignedMessage,
      message: message,
      recipientWallet: recipientWallet,
      validateAddressingConsistency: validateAddressingConsistency,
    );

    if (signedMessage == null) {
      throw ArgumentError(
        'Failed to find Signed Message during unpacking',
        'message',
      );
    }

    return signedMessage;
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

  static Future<(SignedMessage?, PlainTextMessage?)> _unpack({
    required Map<String, dynamic> message,
    required Wallet recipientWallet,
    // Singed or Plain Text Message
    required Type messageTypeToStopUnpacking,
    bool validateAddressingConsistency = true,
  }) async {
    var currentMessage = message;

    while (EncryptedMessage.isEncryptedMessage(currentMessage) ||
        SignedMessage.isSignedMessage(currentMessage)) {
      if (EncryptedMessage.isEncryptedMessage(currentMessage)) {
        final encryptedMessage = EncryptedMessage.fromJson(currentMessage);

        currentMessage = await encryptedMessage.unpack(
          recipientWallet: recipientWallet,
          validateAddressingConsistency: validateAddressingConsistency,
        );
      }

      if (SignedMessage.isSignedMessage(currentMessage)) {
        final signedMessage = SignedMessage.fromJson(currentMessage);

        if (messageTypeToStopUnpacking == SignedMessage) {
          return (signedMessage, null);
        }

        currentMessage = await signedMessage.unpack(
          validateAddressingConsistency: validateAddressingConsistency,
        );
      }
    }

    if (messageTypeToStopUnpacking == PlainTextMessage) {
      final plainTextMessage = PlainTextMessage.fromJson(currentMessage);
      return (null, plainTextMessage);
    }

    return (null, null);
  }

  Map<String, dynamic> toJson();
}
