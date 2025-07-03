// https://identity.foundation/didcomm-messaging/spec/#iana-media-types
import 'package:collection/collection.dart';

import '../../didcomm.dart';

/// The type of message wrapping as defined by the DIDComm Messaging specification.
/// See: https://identity.foundation/didcomm-messaging/spec/#iana-media-types
/// Each variant describes a specific combination of message types and key wrapping algorithms.
enum MessageWrappingType {
  /// Plaintext message wrapping (no signing or encryption).
  ///
  /// [messageTypes]: [PlainTextMessage]
  /// [keyWrappingAlgorithms]: []
  plaintext(
    [
      PlainTextMessage,
    ],
    [],
  ),

  /// Signed plaintext message wrapping (signed but not encrypted).
  ///
  /// [messageTypes]: [SignedMessage, PlainTextMessage]
  /// [keyWrappingAlgorithms]: []
  signedPlaintext(
    [
      SignedMessage,
      PlainTextMessage,
    ],
    [],
  ),

  /// Anoncrypt plaintext message wrapping (anonymously encrypted, not signed).
  ///
  /// [messageTypes]: [EncryptedMessage, PlainTextMessage]
  /// [keyWrappingAlgorithms]: [KeyWrappingAlgorithm.ecdhEs]
  anoncryptPlaintext(
    [
      EncryptedMessage,
      PlainTextMessage,
    ],
    [
      KeyWrappingAlgorithm.ecdhEs,
    ],
  ),

  /// Authcrypt plaintext message wrapping (authenticated encryption, not signed).
  ///
  /// [messageTypes]: [EncryptedMessage, PlainTextMessage]
  /// [keyWrappingAlgorithms]: [KeyWrappingAlgorithm.ecdh1Pu]
  authcryptPlaintext(
    [
      EncryptedMessage,
      PlainTextMessage,
    ],
    [
      KeyWrappingAlgorithm.ecdh1Pu,
    ],
  ),

  /// Anoncrypt signed plaintext message wrapping (anonymously encrypted and signed).
  ///
  /// [messageTypes]: [EncryptedMessage, SignedMessage, PlainTextMessage]
  /// [keyWrappingAlgorithms]: [KeyWrappingAlgorithm.ecdhEs]
  anoncryptSignPlaintext(
    [
      EncryptedMessage,
      SignedMessage,
      PlainTextMessage,
    ],
    [
      KeyWrappingAlgorithm.ecdhEs,
    ],
  ),

  /// Authcrypt signed plaintext message wrapping (authenticated encryption and signed).
  ///
  /// [messageTypes]: [EncryptedMessage, SignedMessage, PlainTextMessage]
  /// [keyWrappingAlgorithms]: [KeyWrappingAlgorithm.ecdh1Pu]
  authcryptSignPlaintext(
    [
      EncryptedMessage,
      SignedMessage,
      PlainTextMessage,
    ],
    [
      KeyWrappingAlgorithm.ecdh1Pu,
    ],
  ),

  /// Anoncrypt and authcrypt plaintext message wrapping (multiple layers of encryption).
  ///
  /// [messageTypes]: [EncryptedMessage, EncryptedMessage, PlainTextMessage]
  /// [keyWrappingAlgorithms]: [KeyWrappingAlgorithm.ecdhEs, KeyWrappingAlgorithm.ecdh1Pu]
  anoncryptAuthcryptPlaintext(
    [
      EncryptedMessage,
      EncryptedMessage,
      PlainTextMessage,
    ],
    [
      KeyWrappingAlgorithm.ecdhEs,
      KeyWrappingAlgorithm.ecdh1Pu,
    ],
  );

  /// The list of message types that define this wrapping type.
  final List<Type> messageTypes;

  /// The list of key wrapping algorithms used in this wrapping type.
  final List<KeyWrappingAlgorithm> keyWrappingAlgorithms;

  static final _typeListEquality = const ListEquality<Type>();
  static final _keyWrappingAlgorithmListEquality =
      const ListEquality<KeyWrappingAlgorithm>();

  static final _jweHeaderConverter = const JweHeaderConverter();

  /// Creates a [MessageWrappingType] with the given [messageTypes] and [keyWrappingAlgorithms].
  const MessageWrappingType(
    this.messageTypes,
    this.keyWrappingAlgorithms,
  );

  /// Finds the [MessageWrappingType] that matches the provided list of [messages].
  ///
  /// Returns the first matching [MessageWrappingType] or null if none matches.
  ///
  /// [messages]: The list of [DidcommMessage]s to analyze.
  static MessageWrappingType? findFromMessages(
    List<DidcommMessage> messages,
  ) {
    return MessageWrappingType.values.firstWhereOrNull(
      (item) {
        final messageTypes = <Type>[];
        final keyWrappingAlgorithms = <KeyWrappingAlgorithm>[];

        for (final message in messages) {
          if (message is EncryptedMessage) {
            final jweHeader = _jweHeaderConverter.fromJson(
              message.protected,
            );

            keyWrappingAlgorithms.add(jweHeader.keyWrappingAlgorithm);
            messageTypes.add(EncryptedMessage);
          } else if (message is SignedMessage) {
            messageTypes.add(SignedMessage);
          } else {
            messageTypes.add(PlainTextMessage);
          }
        }

        return _typeListEquality.equals(
              item.messageTypes,
              messageTypes,
            ) &&
            _keyWrappingAlgorithmListEquality.equals(
              item.keyWrappingAlgorithms,
              keyWrappingAlgorithms,
            );
      },
    );
  }
}
