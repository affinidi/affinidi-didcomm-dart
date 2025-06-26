import 'dart:typed_data';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as pointycastle_utils;

/// Extension methods for [BigInt] to support cryptographic byte conversions.
extension BigIntExtension on BigInt {
  /// Converts this [BigInt] to a [Uint8List] of the specified [length],
  /// encoding as an unsigned big-endian integer.
  ///
  /// [length]: The desired length of the output byte array (default: 32).
  /// If the encoded bytes are shorter than [length], the result is left-padded with zeros.
  /// Throws [ArgumentError] if the encoded bytes are longer than [length].
  ///
  /// Useful for encoding private/public key material for cryptographic operations.
  Uint8List toBytes({int length = 32}) {
    var bytes = pointycastle_utils.encodeBigIntAsUnsigned(this);

    if (bytes.length > length) {
      throw ArgumentError(
        'The length of the byte array is greater than the specified length.',
        'length',
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
