import '../curves/curve_type.dart';

class NotFoundVerificationByCurveError extends StateError {
  NotFoundVerificationByCurveError(CurveType curve)
      : super('Recipient does not have any JWK with matching curve: $curve');
}
