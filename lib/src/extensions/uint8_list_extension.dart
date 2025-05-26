import 'dart:typed_data';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as pointycastle_utils;
import 'package:elliptic/elliptic.dart' as ec;

extension Uint8ListExtension on Uint8List {
  BigInt toBigInt() {
    return pointycastle_utils.decodeBigIntWithSign(1, this);
  }

  ec.PrivateKey toPrivateKey({required ec.Curve curve}) {
    return ec.PrivateKey.fromBytes(curve, this);
  }
}
