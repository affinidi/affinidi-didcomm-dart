import 'dart:convert';
import 'dart:typed_data';

extension ObjectExtension on Object {
  Uint8List toJsonBytes() {
    final jsonString = jsonEncode(this);
    return Uint8List.fromList(utf8.encode(jsonString));
  }
}
