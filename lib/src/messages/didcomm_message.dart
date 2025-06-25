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
    List<MessageWrappingType>? expectedMessageWrappingTypes,
  }) async {
    final foundMessages = <DidcommMessage>[];
    var currentMessage = message;

    while (EncryptedMessage.isEncryptedMessage(currentMessage) ||
        SignedMessage.isSignedMessage(currentMessage)) {
      if (EncryptedMessage.isEncryptedMessage(currentMessage)) {
        final encryptedMessage = EncryptedMessage.fromJson(currentMessage);

        currentMessage = await encryptedMessage.unpack(
          recipientWallet: recipientWallet,
        );

        foundMessages.add(encryptedMessage);
      }

      if (SignedMessage.isSignedMessage(currentMessage)) {
        final signedMessage = SignedMessage.fromJson(currentMessage);
        currentMessage = await signedMessage.unpack();

        foundMessages.add(signedMessage);
      }
    }

    final plainTextMessage = PlainTextMessage.fromJson(currentMessage);
    foundMessages.add(plainTextMessage);

    _validate(
      messages: foundMessages,
      expectedMessageWrappingTypes: expectedMessageWrappingTypes,
      validateAddressingConsistency: validateAddressingConsistency,
    );

    return plainTextMessage;
  }

  static void _validate({
    required List<DidcommMessage> messages,
    required List<MessageWrappingType>? expectedMessageWrappingTypes,
    required bool validateAddressingConsistency,
  }) {
    if (expectedMessageWrappingTypes != null) {
      final currentMessageWrappingType =
          MessageWrappingType.findFromMessages(messages);

      if (currentMessageWrappingType == null) {
        throw UnsupportedError(
          'Can not find matching MessageWrappingType',
        );
      }

      if (!expectedMessageWrappingTypes.contains(currentMessageWrappingType)) {
        throw ArgumentError(
          '$currentMessageWrappingType in not in expected list: $expectedMessageWrappingTypes',
          'message',
        );
      }
    }

    if (validateAddressingConsistency && messages.length > 1) {
      final iterator = messages.reversed.iterator;

      // the 1st message is always Plain Text Message
      iterator.moveNext();
      final plainTextMessage = iterator.current as PlainTextMessage;

      // the 2nd message can be Signed Message or Encrypted Message
      iterator.moveNext();

      if (iterator.current is EncryptedMessage) {
        plainTextMessage.validateConsistencyWithEncryptedMessage(
          iterator.current as EncryptedMessage,
        );

        // encrypted message can't be signed
        return;
      }

      if (iterator.current is SignedMessage) {
        plainTextMessage.validateConsistencyWithSignedMessage(
          iterator.current as SignedMessage,
        );
      }

      // if there is a 3rd message, it is always Encrypted Message
      if (iterator.moveNext()) {
        plainTextMessage.validateConsistencyWithEncryptedMessage(
          iterator.current as EncryptedMessage,
        );
      }
    }
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
