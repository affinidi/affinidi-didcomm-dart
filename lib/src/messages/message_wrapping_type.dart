// https://identity.foundation/didcomm-messaging/spec/#iana-media-types
import 'package:collection/collection.dart';

import '../../didcomm.dart';
import '../converters/jwe_header_converter.dart';

enum MessageWrappingType {
  plaintext(
    [
      PlainTextMessage,
    ],
    [],
  ),
  signedPlaintext(
    [
      SignedMessage,
      PlainTextMessage,
    ],
    [],
  ),
  anoncryptPlaintext(
    [
      EncryptedMessage,
      PlainTextMessage,
    ],
    [
      KeyWrappingAlgorithm.ecdhEs,
    ],
  ),
  authcryptPlaintext(
    [
      EncryptedMessage,
      PlainTextMessage,
    ],
    [
      KeyWrappingAlgorithm.ecdh1Pu,
    ],
  ),
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

  final List<Type> messageTypes;
  final List<KeyWrappingAlgorithm> keyWrappingAlgorithms;

  static final _typeListEquality = const ListEquality<Type>();
  static final _keyWrappingAlgorithmListEquality =
      const ListEquality<KeyWrappingAlgorithm>();

  static final _jweHeaderConverter = const JweHeaderConverter();

  const MessageWrappingType(
    this.messageTypes,
    this.keyWrappingAlgorithms,
  );

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
