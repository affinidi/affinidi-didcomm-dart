import '../curves/curve_type.dart';

class NotFoundJwkErrorByCurve extends StateError {
  NotFoundJwkErrorByCurve(CurveType curve)
    : super('Recipient does not have any JWK with matching curve: $curve');
}
