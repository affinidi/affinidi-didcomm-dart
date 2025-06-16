import '../../messages/algorithm_types/algorithms_types.dart';

class MessageOptions {
  final bool shouldSign;
  final bool shouldEncrypt;
  final KeyWrappingAlgorithm keyWrappingAlgorithm;
  final EncryptionAlgorithm encryptionAlgorithm;

  const MessageOptions({
    this.shouldSign = false,
    this.shouldEncrypt = false,
    this.keyWrappingAlgorithm = KeyWrappingAlgorithm.ecdhEs,
    this.encryptionAlgorithm = EncryptionAlgorithm.a256cbc,
  });
}
