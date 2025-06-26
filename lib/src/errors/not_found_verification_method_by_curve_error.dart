import '../curves/curve_type.dart';

/// Error thrown when no verification method with a matching curve is found for a recipient.
class NotFoundVerificationMethodByCurveError extends StateError {
  /// Constructs a [NotFoundVerificationMethodByCurveError].
  ///
  /// [curve]: The curve type for which no verification method was found.
  NotFoundVerificationMethodByCurveError(CurveType curve)
      : super('Recipient does not have any JWK with matching curve: $curve');
}
