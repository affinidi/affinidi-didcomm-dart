import '../curves/curve_type.dart';

class UnsupportedCurveError extends UnsupportedError {
  UnsupportedCurveError(CurveType curve) : super('$curve is not supported');
}
