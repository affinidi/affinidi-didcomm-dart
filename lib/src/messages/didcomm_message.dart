import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/converters/jwe_header_converter.dart';
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
    List<MessageWrappingType>? expectedMessageWrappingTypes,
  }) async {
    final jweHeaderConverter = JweHeaderConverter();
    var currentMessage = message;

    final messageTypeChain = <Type>[];
    final keyWrappingAlgorithmChain = <KeyWrappingAlgorithm>[];

    while (EncryptedMessage.isEncryptedMessage(currentMessage) ||
        SignedMessage.isSignedMessage(currentMessage)) {
      if (EncryptedMessage.isEncryptedMessage(currentMessage)) {
        final encryptedMessage = EncryptedMessage.fromJson(currentMessage);

        currentMessage = await encryptedMessage.unpack(
          recipientWallet: recipientWallet,
          validateAddressingConsistency: validateAddressingConsistency,
        );

        final jweHeader = jweHeaderConverter.fromJson(
          encryptedMessage.protected,
        );

        keyWrappingAlgorithmChain.add(jweHeader.keyWrappingAlgorithm);
        messageTypeChain.add(EncryptedMessage);
      }

      if (SignedMessage.isSignedMessage(currentMessage)) {
        final signedMessage = SignedMessage.fromJson(currentMessage);

        currentMessage = await signedMessage.unpack(
          validateAddressingConsistency: validateAddressingConsistency,
        );

        messageTypeChain.add(SignedMessage);
      }
    }

    messageTypeChain.add(PlainTextMessage);

    if (expectedMessageWrappingTypes != null) {
      final currentMessageWrappingType = MessageWrappingType.find(
        messageTypeChain: messageTypeChain,
        keyWrappingAlgorithmChain: keyWrappingAlgorithmChain,
      );

      if (currentMessageWrappingType == null) {
        throw UnsupportedError(
          'Can not find matching MessageWrappingType for $messageTypeChain and $keyWrappingAlgorithmChain',
        );
      }

      if (!expectedMessageWrappingTypes.contains(currentMessageWrappingType)) {
        throw ArgumentError(
          'Unexpected message wrapping type: $currentMessageWrappingType',
          'message',
        );
      }
    }

    return PlainTextMessage.fromJson(currentMessage);
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

  Map<String, dynamic> toJson();
}
