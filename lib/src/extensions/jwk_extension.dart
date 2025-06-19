import 'package:elliptic/elliptic.dart' as ec;

import '../curves/curve_type.dart';
import '../errors/errors.dart';
import '../jwks/jwk.dart';
import 'uint8_list_extension.dart';

extension JwkExtension on Jwk {
  ec.PublicKey toPublicKeyFromPoint() {
    if (curve == null) {
      throw ArgumentError('curve is required', 'curve');
    }

    if (x == null) {
      throw ArgumentError('x is required', 'x');
    }

    if (y == null) {
      throw ArgumentError('y is required', 'y');
    }

    return ec.PublicKey.fromPoint(
      _createSecp256OrPCurveCurveByType(curve!),
      ec.AffinePoint.fromXY(x!.toBigInt(), y!.toBigInt()),
    );
  }

  ec.Curve _createSecp256OrPCurveCurveByType(CurveType curveType) {
    if (curveType == CurveType.p256) {
      return ec.getP256();
    }

    if (curveType == CurveType.secp256k1) {
      return ec.getSecp256k1();
    }

    throw UnsupportedCurveError(curveType);
  }
}
