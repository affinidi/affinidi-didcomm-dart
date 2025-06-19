import 'package:collection/collection.dart';
import 'package:ssi/ssi.dart' hide Jwk;

import '../../didcomm.dart';
import '../curves/curve_type.dart';
import '../jwks/jwk.dart';

extension VerificationMethodExtention on VerificationMethod {
  Jwk toJwk() {
    final jwk = asJwk().toJson();
    return Jwk.fromJson(jwk);
  }
}

extension VerificationMethodListExtention on List<VerificationMethod> {
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
