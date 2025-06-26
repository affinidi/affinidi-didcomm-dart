import '../messages/algorithm_types/key_wrapping_algorithm.dart';

/// Error thrown when an unsupported key wrapping algorithm is encountered in DIDComm operations.
class UnsupportedKeyWrappingAlgorithmError extends UnsupportedError {
  /// Constructs an [UnsupportedKeyWrappingAlgorithmError].
  ///
  /// [keyWrappingAlgorithm]: The unsupported key wrapping algorithm.
  UnsupportedKeyWrappingAlgorithmError(
    KeyWrappingAlgorithm keyWrappingAlgorithm,
  ) : super('$keyWrappingAlgorithm is not supported');
}
