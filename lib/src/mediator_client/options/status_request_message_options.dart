import 'message_options.dart';

/// Options for sending a status request message over a DIDComm mediator.
///
/// Allows configuration of whether to send the message and how it should be protected (signing, encryption, etc).
class StatusRequestMessageOptions extends MessageOptions {
  /// Whether a status request message should be sent.
  ///
  /// Default is false.
  final bool shouldSend;

  /// Constructs [StatusRequestMessageOptions].
  ///
  /// [shouldSend]: Whether to send the status request message (default: false).
  /// [shouldSign]: Whether the message should be signed (inherited from [MessageOptions]).
  /// [shouldEncrypt]: Whether the message should be encrypted (inherited from [MessageOptions]).
  /// [encryptionAlgorithm]: The encryption algorithm to use (inherited from [MessageOptions]).
  /// [keyWrappingAlgorithm]: The key wrapping algorithm to use (inherited from [MessageOptions]).
  const StatusRequestMessageOptions({
    this.shouldSend = false,
    super.shouldSign,
    super.shouldEncrypt,
    super.encryptionAlgorithm,
    super.keyWrappingAlgorithm,
  });
}
