import 'dart:convert';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as pointycastle_utils;
import 'package:ssi/ssi.dart' show KeyType;
import 'package:collection/collection.dart';
import 'package:elliptic/elliptic.dart' as ec;

import '../common/encoding.dart';
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

extension BigIntExtension on BigInt {
  Uint8List toBytes({int length = 32}) {
    var bytes =
        this < BigInt.zero
            ? pointycastle_utils.encodeBigInt(this)
            : pointycastle_utils.encodeBigIntAsUnsigned(this);

    if (bytes.length > length) {
      throw ArgumentError(
        'The length of the byte array is greater than the specified length.',
      );
    }

    if (bytes.length < length) {
      final padded = Uint8List(length);

      padded.setRange(length - bytes.length, length, bytes);
      bytes = padded;
    }

    return bytes;
  }
}
