import 'package:ssi/ssi.dart' show KeyType;
import '../curves/curve_type.dart';
import '../errors/errors.dart';

extension KeyTypeExtension on KeyType {
  CurveType asDidcommCompatibleCurve() {
    if (this == KeyType.p256) {
      return CurveType.p256;
    }

    if (this == KeyType.secp256k1) {
      return CurveType.secp256k1;
    }

    if (this == KeyType.ed25519) {
      // we can't use ed25519 directly so we use similar x25519 curve
      return CurveType.x25519;
    }

    throw UnsupportedKeyTypeError(this);
  }
}
