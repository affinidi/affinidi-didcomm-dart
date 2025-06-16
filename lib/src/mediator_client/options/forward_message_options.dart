import 'message_options.dart';

class ForwardMessageOptions extends MessageOptions {
  const ForwardMessageOptions({
    super.shouldSign,
    super.shouldEncrypt,
    super.keyWrappingAlgorithm,
    super.encryptionAlgorithm,
  });
}
