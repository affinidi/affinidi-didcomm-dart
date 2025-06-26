import 'package:collection/collection.dart';
import 'package:ssi/ssi.dart' hide Jwk;

import '../../didcomm.dart';
import '../curves/curve_type.dart';
import '../jwks/jwk.dart';

/// Extension methods for [VerificationMethod] to support JWK conversion.
extension VerificationMethodExtention on VerificationMethod {
  /// Converts this [VerificationMethod] to a [Jwk] object.
  ///
  /// Returns the [Jwk] representation of the verification method.
  Jwk toJwk() {
    final jwk = asJwk().toJson();
    return Jwk.fromJson(jwk);
  }
}

/// Extension methods for [List<VerificationMethod>] to support curve-based lookup.
extension VerificationMethodListExtention on List<VerificationMethod> {
  /// Returns the first [VerificationMethod] in the list with the given [curve].
  ///
  /// [curve]: The [CurveType] to match.
  /// Throws [NotFoundVerificationByCurveError] if no matching verification method is found.
  VerificationMethod firstWithCurve(CurveType curve) {
    final match = firstWhereOrNull(
      (verificationMethod) => verificationMethod.toJwk().curve == curve,
    );

    if (match == null) {
      throw NotFoundVerificationByCurveError(curve);
    }

    return match;
  }
}
