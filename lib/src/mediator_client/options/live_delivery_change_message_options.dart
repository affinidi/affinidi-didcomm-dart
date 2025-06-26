import 'message_options.dart';

/// Options for sending a live delivery change message over a DIDComm mediator.
///
/// Allows configuration of whether to send the message and how it should be protected (signing, encryption, etc).
class LiveDeliveryChangeMessageOptions extends MessageOptions {
  /// Whether a live delivery change message should be sent.
  ///
  /// Default is false.
  final bool shouldSend;

  /// Constructs [LiveDeliveryChangeMessageOptions].
  ///
  /// [shouldSend]: Whether to send the live delivery change message (default: false).
  /// [shouldSign]: Whether the message should be signed (inherited from [MessageOptions]).
  /// [shouldEncrypt]: Whether the message should be encrypted (inherited from [MessageOptions]).
  /// [encryptionAlgorithm]: The encryption algorithm to use (inherited from [MessageOptions]).
  /// [keyWrappingAlgorithm]: The key wrapping algorithm to use (inherited from [MessageOptions]).
  const LiveDeliveryChangeMessageOptions({
    this.shouldSend = false,
    super.shouldSign,
    super.shouldEncrypt,
    super.encryptionAlgorithm,
    super.keyWrappingAlgorithm,
  });
}
