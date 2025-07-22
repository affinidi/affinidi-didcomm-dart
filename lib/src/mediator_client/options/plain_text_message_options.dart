import '../../../didcomm.dart';

/// Options for sending a [ForwardMessageOptions] message over a DIDComm mediator or next hop.
///
/// Allows configuration of how the message should be protected (signing, encryption, etc).
class ForwardMessageOptions extends MessageOptions {
  /// Constructs [ForwardMessageOptions].
  ///
  /// [shouldSign]: Whether the message should be signed (inherited from [MessageOptions]).
  /// [shouldEncrypt]: Whether the message should be encrypted (inherited from [MessageOptions]).
  /// [keyWrappingAlgorithm]: The key wrapping algorithm to use (inherited from [MessageOptions]).
  /// [encryptionAlgorithm]: The encryption algorithm to use (inherited from [MessageOptions]).
  const ForwardMessageOptions({
    super.shouldSign,
    super.shouldEncrypt,
    super.keyWrappingAlgorithm,
    super.encryptionAlgorithm,
  });
}
