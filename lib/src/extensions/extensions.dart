import 'dart:convert';
import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import '../curves/curve_type.dart';
import '../errors/errors.dart';

extension JsonBytesExtension on Object {
  Uint8List toJsonBytes() {
    final jsonString = jsonEncode(this);
    return Uint8List.fromList(utf8.encode(jsonString));
  }
}

extension KeyTypeExtension on KeyType {
  CurveType asDidcommCurve() {
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
