import '../messages/algorithm_types/algorithms_types.dart';

/// Error thrown when an unsupported encryption algorithm is encountered in DIDComm operations.
class UnsupportedEncryptionAlgorithmError extends UnsupportedError {
  /// Constructs an [UnsupportedEncryptionAlgorithmError].
  ///
  /// [encryptionAlgorithm]: The unsupported encryption algorithm.
  UnsupportedEncryptionAlgorithmError(EncryptionAlgorithm encryptionAlgorithm)
      : super('$encryptionAlgorithm is not supported');
}
