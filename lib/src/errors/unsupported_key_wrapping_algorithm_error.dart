import '../messages/algorithm_types/key_wrapping_algorithm.dart';

class UnsupportedKeyWrappingAlgorithmError extends UnsupportedError {
  UnsupportedKeyWrappingAlgorithmError(
    KeyWrappingAlgorithm keyWrappingAlgorithm,
  ) : super('$keyWrappingAlgorithm is not supported');
}
