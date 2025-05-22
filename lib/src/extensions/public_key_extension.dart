import 'dart:typed_data';

import 'package:elliptic/elliptic.dart' as ec;
import 'package:convert/convert.dart';

extension PublicKeyExtension on ec.PublicKey {
  Uint8List toBytes() {
    return Uint8List.fromList(hex.decode(toHex()));
  }
}
