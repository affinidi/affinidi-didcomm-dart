import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:elliptic/elliptic.dart' as ec;

/// Extension methods for [ec.PublicKey] to support byte conversion.
extension PublicKeyExtension on ec.PublicKey {
  /// Converts this [ec.PublicKey] to a [Uint8List] containing its compressed representation.
  ///
  /// Returns the bytes of the compressed public key, decoded from its hex string.
  Uint8List toBytes() {
    return Uint8List.fromList(hex.decode(toCompressedHex()));
  }
}
