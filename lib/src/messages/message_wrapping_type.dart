// https://identity.foundation/didcomm-messaging/spec/#iana-media-types
import 'package:collection/collection.dart';

import '../../didcomm.dart';

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

  final List<Type> messageTypeChain;
  final List<KeyWrappingAlgorithm> keyWrappingAlgorithmChain;

  static final _listEquality = const ListEquality();

  const MessageWrappingType(
    this.messageTypeChain,
    this.keyWrappingAlgorithmChain,
  );

  static MessageWrappingType? find({
    required List<Type> messageTypeChain,
    required List<KeyWrappingAlgorithm> keyWrappingAlgorithmChain,
  }) {
    return MessageWrappingType.values.firstWhereOrNull(
      (item) =>
          _listEquality.equals(
            item.messageTypeChain,
            messageTypeChain,
          ) &&
          _listEquality.equals(
            item.keyWrappingAlgorithmChain,
            keyWrappingAlgorithmChain,
          ),
    );
  }
}
