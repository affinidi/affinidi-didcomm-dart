import '../curves/curve_type.dart';

/// Error thrown when an unsupported elliptic curve is encountered in DIDComm operations.
class UnsupportedCurveError extends UnsupportedError {
  /// Constructs an [UnsupportedCurveError].
  ///
  /// [curve]: The unsupported curve type.
  UnsupportedCurveError(CurveType curve) : super('$curve is not supported');
}
