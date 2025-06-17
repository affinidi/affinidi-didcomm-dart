import '../messages/algorithm_types/algorithms_types.dart';

class UnsupportedEncryptionAlgorithmError extends UnsupportedError {
  UnsupportedEncryptionAlgorithmError(EncryptionAlgorithm encryptionAlgorithm)
      : super('$encryptionAlgorithm is not supported');
}
