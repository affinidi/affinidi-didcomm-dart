import 'package:elliptic/elliptic.dart' as ec;

import '../curves/curve_type.dart';
import '../errors/errors.dart';
import '../jwks/jwk.dart';
import 'uint8_list_extension.dart';

/// Extension methods for [Jwk] to support conversion to elliptic curve public keys.
extension JwkExtension on Jwk {
  /// Converts this [Jwk] to an [ec.PublicKey] using the curve and point coordinates.
  ///
  /// Throws [ArgumentError] if the curve, x, or y fields are missing.
  /// Throws [UnsupportedCurveError] if the curve is not supported.
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

    if (curveType == CurveType.p384) {
      return ec.getP384();
    }

    if (curveType == CurveType.p521) {
      return ec.getP521();
    }

    if (curveType == CurveType.secp256k1) {
      return ec.getSecp256k1();
    }

    throw UnsupportedCurveError(curveType);
  }
}
