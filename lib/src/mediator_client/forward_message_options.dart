import '../messages/algorithm_types/algorithms_types.dart';

class ForwardMessageOptions {
  final bool shouldSign;
  final bool shouldEncrypt;
  final KeyWrappingAlgorithm keyWrappingAlgorithm;
  final EncryptionAlgorithm encryptionAlgorithm;

  const ForwardMessageOptions({
    this.shouldSign = false,
    this.shouldEncrypt = false,
    this.keyWrappingAlgorithm = KeyWrappingAlgorithm.ecdhEs,
    this.encryptionAlgorithm = EncryptionAlgorithm.a256cbc,
  });
}
