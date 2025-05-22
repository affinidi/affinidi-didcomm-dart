import 'dart:typed_data';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as pointycastle_utils;

extension BigIntExtension on BigInt {
  // TODO: check length for P-384 and P-521 curves
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
