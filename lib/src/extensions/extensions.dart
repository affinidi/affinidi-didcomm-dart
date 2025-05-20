import 'dart:convert';
import 'dart:typed_data';

import 'package:ssi/ssi.dart' show KeyType;
import 'package:collection/collection.dart';

import '../curves/curve_type.dart';
import '../errors/errors.dart';
import '../jwks/jwks.dart';

extension JsonBytesExtension on Object {
  Uint8List toJsonBytes() {
    final jsonString = jsonEncode(this);
    return Uint8List.fromList(utf8.encode(jsonString));
  }
}

extension KeyTypeExtension on KeyType {
  CurveType asDidcommCompatibleCurve() {
    if (this == KeyType.p256) {
      return CurveType.p256;
    } else if (this == KeyType.secp256k1) {
      return CurveType.secp256k1;
    } else if (this == KeyType.ed25519) {
      // we can't use ed25519 directly so we use similar x25519 curve
      return CurveType.x25519;
    }

    throw UnsupportedKeyTypeError(this);
  }
}

extension JwksCurveExtension on Jwks {
  Jwk firstWithCurve(CurveType curve) {
    final match = keys.firstWhereOrNull((jwk) => jwk.curve == curve);

    if (match == null) {
      throw NotFoundJwkErrorByCurve(curve);
    }

    return match;
  }
}
