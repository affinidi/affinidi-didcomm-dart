// https://identity.foundation/didcomm-messaging/spec/#iana-media-types
import '../../didcomm.dart';

enum MessageWrappingType {
  plaintext([
    PlainTextMessage,
  ]),
  signedPlaintext([
    SignedMessage,
    PlainTextMessage,
  ]),
  anoncryptPlaintext([
    EncryptedMessage,
    PlainTextMessage,
  ]),
  authcryptPlaintext([
    EncryptedMessage,
    PlainTextMessage,
  ]),
  anoncryptSignPlaintext([
    EncryptedMessage,
    SignedMessage,
    PlainTextMessage,
  ]),
  authcryptSignPlaintext([
    EncryptedMessage,
    SignedMessage,
    PlainTextMessage,
  ]),
  anoncryptAuthcryptPlaintext([
    EncryptedMessage,
    EncryptedMessage,
    PlainTextMessage,
  ]);

  final List<Type> messageTypeChain;
  const MessageWrappingType(this.messageTypeChain);
}
