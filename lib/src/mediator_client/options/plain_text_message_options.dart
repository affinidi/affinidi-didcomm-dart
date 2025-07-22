import '../../../didcomm.dart';

/// Options for sending a [PlainTextMessage] message over a DIDComm mediator or next hop.
///
/// Allows configuration of how the message should be protected (signing, encryption, etc).
class PlainTextMessageOptions extends MessageOptions {
  /// Constructs [PlainTextMessageOptions].
  ///
  /// [shouldSign]: Whether the message should be signed (inherited from [MessageOptions]).
  /// [shouldEncrypt]: Whether the message should be encrypted (inherited from [MessageOptions]).
  /// [keyWrappingAlgorithm]: The key wrapping algorithm to use (inherited from [MessageOptions]).
  /// [encryptionAlgorithm]: The encryption algorithm to use (inherited from [MessageOptions]).
  const PlainTextMessageOptions({
    super.shouldSign,
    super.shouldEncrypt,
    super.keyWrappingAlgorithm,
    super.encryptionAlgorithm,
  });
}
