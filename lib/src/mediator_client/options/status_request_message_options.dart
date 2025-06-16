import 'message_options.dart';

class StatusRequestMessageOptions extends MessageOptions {
  final bool shouldSend;

  const StatusRequestMessageOptions({
    this.shouldSend = false,
    super.shouldSign,
    super.shouldEncrypt,
    super.encryptionAlgorithm,
    super.keyWrappingAlgorithm,
  });
}
