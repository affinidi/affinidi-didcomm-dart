import 'dart:typed_data';

import 'package:elliptic/elliptic.dart' as ec;
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as pointycastle_utils;

/// Extension methods for [Uint8List] to support cryptographic conversions.
extension Uint8ListExtension on Uint8List {
  /// Converts this [Uint8List] to a [BigInt] using unsigned big-endian encoding.
  ///
  /// Returns the decoded [BigInt] value.
  BigInt toBigInt() {
    return pointycastle_utils.decodeBigIntWithSign(1, this);
  }

  /// Converts this [Uint8List] to an [ec.PrivateKey] for the given [curve].
  ///
  /// [curve]: The elliptic curve to use for the private key.
  /// Returns the [ec.PrivateKey] created from these bytes.
  ec.PrivateKey toPrivateKey({required ec.Curve curve}) {
    return ec.PrivateKey.fromBytes(curve, this);
  }
}
