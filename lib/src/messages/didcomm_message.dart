import 'package:meta/meta.dart';
import 'package:ssi/ssi.dart';

import '../../didcomm.dart';

/// Abstract base class for DIDComm messages.
///
/// Provides common functionality for message packing and unpacking
/// according to the DIDComm Messaging specification.
/// See: https://identity.foundation/didcomm-messaging/spec/
abstract class DidcommMessage {
  /// Constructs a [DidcommMessage].
  DidcommMessage();

  /// The default media type for plain DIDComm messages as per the spec.
  static final mediaType = 'application/didcomm-plain+json';
  final Map<String, dynamic> _customHeaders = {};

  /// Gets a custom header value by [key].
  dynamic operator [](String key) => _customHeaders[key];

  /// Sets a custom header [value] for the given [key].
  void operator []=(String key, dynamic value) => _customHeaders[key] = value;

  /// Packs a [PlainTextMessage] into a [SignedMessage] using the provided [signer].
  ///
  /// Use this when you want to provide non-repudiation and message integrity, but do not require confidentiality (encryption).
  ///
  /// Returns a [SignedMessage] containing the signed payload.
  static Future<SignedMessage> packIntoSignedMessage(
    PlainTextMessage message, {
    required DidSigner signer,
  }) async {
    return await SignedMessage.pack(
      message,
      signer: signer,
    );
  }

  /// Packs a [PlainTextMessage] into an [EncryptedMessage] using the provided cryptographic parameters.
  ///
  /// Use this when you want to send a confidential message and do not require non-repudiation. The message can be either a plain text or a signed message.
  ///
  /// Encryption type is determined by the provided arguments:
  /// - **Authenticated Encryption (authcrypt, ECDH-1PU):** Provide [keyPair] and [didKeyId] (sender's key and key ID). Used when sender authenticity is required.
  /// - **Anonymous Encryption (anoncrypt, ECDH-ES):** Provide [keyType] (recipient's key type) and omit [keyPair] and [didKeyId]. Used when sender anonymity is required.
  ///
  /// [keyPair]: The sender's key pair for authenticated encryption (authcrypt, ECDH-1PU). Required for authcrypt, not used for anoncrypt.
  /// [didKeyId]: The sender's key ID for authenticated encryption (authcrypt, ECDH-1PU). Required for authcrypt, not used for anoncrypt.
  /// [keyType]: The recipient's key type for anonymous encryption (anoncrypt, ECDH-ES). Required for anoncrypt, not used for authcrypt.
  /// [recipientDidDocuments]: List of recipient DID Documents.
  /// [keyWrappingAlgorithm]: Algorithm for key wrapping.
  /// [encryptionAlgorithm]: Algorithm for content encryption.
  ///
  /// Returns an [EncryptedMessage].
  static Future<EncryptedMessage> packIntoEncryptedMessage(
    PlainTextMessage message, {
    KeyPair? keyPair,
    String? didKeyId,
    KeyType? keyType,
    required List<DidDocument> recipientDidDocuments,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    return await EncryptedMessage.pack(
      message,
      keyPair: keyPair,
      didKeyId: didKeyId,
      keyType: keyType,
      recipientDidDocuments: recipientDidDocuments,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  /// Packs a [PlainTextMessage] into a [SignedMessage] and then into an [EncryptedMessage].
  ///
  /// Use this when you want to provide both non-repudiation (via signature) and confidentiality (via encryption) in a single step.
  /// The message is first signed, then encrypted.
  ///
  /// Encryption type is determined by the provided arguments:
  /// - **Authenticated Encryption (authcrypt, ECDH-1PU):** Provide [keyPair] and [didKeyId] (sender's key and key ID). Used when sender authenticity is required.
  /// - **Anonymous Encryption (anoncrypt, ECDH-ES):** Provide [keyType] (recipient's key type) and omit [keyPair] and [didKeyId]. Used when sender anonymity is required.
  ///
  /// [keyPair]: The sender's key pair for authenticated encryption (authcrypt, ECDH-1PU). Required for authcrypt, not used for anoncrypt.
  /// [didKeyId]: The sender's key ID for authenticated encryption (authcrypt, ECDH-1PU). Required for authcrypt, not used for anoncrypt.
  /// [keyType]: The recipient's key type for anonymous encryption (anoncrypt, ECDH-ES). Required for anoncrypt, not used for authcrypt.
  /// [recipientDidDocuments]: List of recipient DID Documents.
  /// [keyWrappingAlgorithm]: Algorithm for key wrapping.
  /// [encryptionAlgorithm]: Algorithm for content encryption.
  /// [signer]: The signer to use for signing the message.
  ///
  /// Returns an [EncryptedMessage] containing the signed payload.
  static Future<EncryptedMessage> packIntoSignedAndEncryptedMessages(
    PlainTextMessage message, {
    KeyPair? keyPair,
    String? didKeyId,
    KeyType? keyType,
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
      keyType: keyType,
      recipientDidDocuments: recipientDidDocuments,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
    );
  }

  /// Unpacks a [PlainTextMessage], recursively decrypting and verifying signatures
  /// of intermediary [EncryptedMessage] and [SignedMessage].
  /// Verifies addressing consistency by default.
  /// Verifies wrapping types (plaintext, authcryptPlaintext, authcryptSignPlaintext, etc)
  /// against the expected list if provided.
  /// Verified signers against the expected list if provided.
  ///
  /// [message]: The message as a JSON map.
  /// [recipientDidController]: The DID controller to use for decryption.
  /// [validateAddressingConsistency]: Whether to validate addressing consistency between wrappers (default is true).
  /// [expectedMessageWrappingTypes]: List of expected message wrapping types (optional).
  ///   For example: [MessageWrappingType.authcryptSignPlaintext, MessageWrappingType.authcryptPlaintext].
  ///   If null, [MessageWrappingType.authcryptPlaintext] is expected by default according to the DIDComm spec.
  /// [expectedSigners]: List of expected signer key IDs (optional).
  /// [onUnpacked]: Optional callback invoked with the list of all unpacked [DidcommMessage]s (from outermost to innermost) after unpacking is complete.
  ///
  /// Returns the [PlainTextMessage].
  static Future<PlainTextMessage> unpackToPlainTextMessage({
    required Map<String, dynamic> message,
    required DidController recipientDidController,
    bool validateAddressingConsistency = true,
    List<MessageWrappingType>? expectedMessageWrappingTypes,
    List<String>? expectedSigners,
    void Function({
      required List<DidcommMessage> foundMessages,
      required List<String> foundSigners,
    })? onUnpacked,
  }) async {
    final foundMessages = <DidcommMessage>[];
    final foundSigners = <String>[];

    var currentMessage = message;

    while (EncryptedMessage.isEncryptedMessage(currentMessage) ||
        SignedMessage.isSignedMessage(currentMessage)) {
      if (EncryptedMessage.isEncryptedMessage(currentMessage)) {
        final encryptedMessage = EncryptedMessage.fromJson(currentMessage);

        currentMessage = await encryptedMessage.unpack(
          recipientDidController: recipientDidController,
        );

        foundMessages.add(encryptedMessage);
      }

      if (SignedMessage.isSignedMessage(currentMessage)) {
        final signedMessage = SignedMessage.fromJson(currentMessage);
        currentMessage = await signedMessage.unpack();

        foundSigners.addAll(
          signedMessage.signatures.map((signature) => signature.header.keyId),
        );

        foundMessages.add(signedMessage);
      }
    }

    final plainTextMessage = PlainTextMessage.fromJson(currentMessage);
    foundMessages.add(plainTextMessage);

    _validate(
      messages: foundMessages,
      validateAddressingConsistency: validateAddressingConsistency,
      expectedMessageWrappingTypes: expectedMessageWrappingTypes,
      expectedSigners: expectedSigners,
    );

    if (onUnpacked != null) {
      onUnpacked(
        foundMessages: foundMessages,
        foundSigners: foundSigners,
      );
    }

    return plainTextMessage;
  }

  /// Merges [json] with custom headers for serialization.
  @protected
  Map<String, dynamic> withCustomHeaders(Map<String, dynamic> json) {
    return {...json, ..._customHeaders};
  }

  /// Assigns custom headers from [json] that are not in [ownHeaders].
  @protected
  void assignCustomHeaders(Map<String, dynamic> json, List<String> ownHeaders) {
    final customHeaders = json.keys.where((key) => !ownHeaders.contains(key));

    for (final key in customHeaders) {
      this[key] = json[key];
    }
  }

  /// Serializes the message to a JSON map, including custom headers.
  Map<String, dynamic> toJson();

  static void _validate({
    required List<DidcommMessage> messages,
    bool validateAddressingConsistency = false,
    List<MessageWrappingType>? expectedMessageWrappingTypes,
    List<String>? expectedSigners,
  }) {
    _validateMessageWrappingType(
      messages: messages,
      expectedMessageWrappingTypes: expectedMessageWrappingTypes,
    );

    _validateSigners(
      messages: messages,
      expectedSigners: expectedSigners,
    );

    _validateAddressingConsistency(
      messages: messages,
      validateAddressingConsistency: validateAddressingConsistency,
    );
  }

  static void _validateMessageWrappingType({
    required List<MessageWrappingType>? expectedMessageWrappingTypes,
    required List<DidcommMessage> messages,
  }) {
    expectedMessageWrappingTypes ??= [MessageWrappingType.authcryptPlaintext];

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

  static void _validateAddressingConsistency({
    required List<DidcommMessage> messages,
    required bool validateAddressingConsistency,
  }) {
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

  static void _validateSigners({
    required List<DidcommMessage> messages,
    List<String>? expectedSigners,
  }) {
    if (expectedSigners != null) {
      if (messages.length < 2) {
        throw ArgumentError(
          'It should be at least 2 messages to start signers validation: Signer Message and Plain Text message',
          'message',
        );
      }

      // the last is Plain Text Message, which follows Signed Message
      final message = messages[messages.length - 2];

      if (message is! SignedMessage) {
        throw ArgumentError(
          'Can not find Signed Messages that wraps Plain Text Message',
          'message',
        );
      }

      final expectedSignerSet = expectedSigners.toSet();

      final actualSignerSet = message.signatures
          .map(
            (signature) => signature.header.keyId,
          )
          .toSet();

      if (!actualSignerSet.containsAll(expectedSigners)) {
        throw ArgumentError(
          'Can not match expected signers: ${expectedSignerSet.difference(actualSignerSet)}',
          'message',
        );
      }
    }
  }
}
