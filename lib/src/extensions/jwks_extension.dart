import '../curves/curve_type.dart';
import '../errors/errors.dart';
import '../jwks/jwks.dart';
import 'package:collection/collection.dart';

extension JwksCurveExtension on Jwks {
  Jwk firstWithCurve(CurveType curve) {
    final match = keys.firstWhereOrNull((jwk) => jwk.curve == curve);

    if (match == null) {
      throw NotFoundJwkErrorByCurve(curve);
    }

    return match;
  }
}
