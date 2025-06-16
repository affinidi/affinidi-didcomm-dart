import 'message_options.dart';

class LiveDeliveryChangeMessageOptions extends MessageOptions {
  final bool shouldSend;

  const LiveDeliveryChangeMessageOptions({
    this.shouldSend = false,
    super.shouldSign,
    super.shouldEncrypt,
    super.encryptionAlgorithm,
    super.keyWrappingAlgorithm,
  });
}
