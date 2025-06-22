import 'package:collection/collection.dart';
import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/did.dart';
import 'package:didcomm/src/converters/jwe_header_converter.dart';
import 'package:ssi/ssi.dart';
import 'package:meta/meta.dart';

class DidcommMessage {
  DidcommMessage();

  static final mediaType = 'application/didcomm-plain+json';
  static final _unorderedEquality = const UnorderedIterableEquality();

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
    DidcommMessage message, {
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
  }) async {
    final (_, plaintextMessage) = await _unpack(
      messageTypeToStopUnpacking: PlainTextMessage,
      message: message,
      recipientWallet: recipientWallet,
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
  }) async {
    final (signedMessage, _) = await _unpack(
      messageTypeToStopUnpacking: SignedMessage,
      message: message,
      recipientWallet: recipientWallet,
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
  }) async {
    var currentMessage = message;

    List<Recipient>? recipients;
    KeyWrappingAlgorithm? keyWrappingAlgorithm;

    while (EncryptedMessage.isEncryptedMessage(currentMessage) ||
        SignedMessage.isSignedMessage(currentMessage)) {
      if (EncryptedMessage.isEncryptedMessage(currentMessage)) {
        final encryptedMessage = EncryptedMessage.fromJson(currentMessage);

        // for case anoncrypt(authcrypt)
        if (recipients != null) {
          final areEqual = _unorderedEquality.equals(
            recipients,
            encryptedMessage.recipients,
          );

          if (!areEqual) {
            throw ArgumentError(
              'Recipients for outer and inners Encrypted Messages do not match',
              'message',
            );
          }
        }

        keyWrappingAlgorithm = JweHeaderConverter()
            .fromJson(encryptedMessage.protected)
            .keyWrappingAlgorithm;
        recipients = encryptedMessage.recipients;

        currentMessage = await encryptedMessage.unpack(
          recipientWallet: recipientWallet,
        );
      }

      if (SignedMessage.isSignedMessage(currentMessage)) {
        final signedMessage = SignedMessage.fromJson(currentMessage);

        if (messageTypeToStopUnpacking == SignedMessage) {
          return (signedMessage, null);
        }

        currentMessage = await signedMessage.unpack();
      }
    }

    if (messageTypeToStopUnpacking == PlainTextMessage) {
      final plainTextMessage = PlainTextMessage.fromJson(currentMessage);

      // https://identity.foundation/didcomm-messaging/spec/#message-layer-addressing-consistency
      final recipientKeyIds = recipients?.map(
        (recipient) => getDidFromId(recipient.header.keyId),
      );

      if (recipientKeyIds != null) {
        if (plainTextMessage.to == null) {
          throw ArgumentError(
            'to header is required if a Plain Message is inside of Encrypted Message',
            'message',
          );
        }

        final areEqual = _unorderedEquality.equals(
          recipientKeyIds,
          plainTextMessage.to,
        );

        if (!areEqual) {
          throw ArgumentError(
            'Recipients in an Encrypted Message do not match recipients IDs in a Plain Text Message',
          );
        }
      }

      return (null, plainTextMessage);
    }

    return (null, null);
  }
}
