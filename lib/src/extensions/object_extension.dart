import 'dart:convert';
import 'dart:typed_data';

/// Extension methods for [Object] to support JSON representation to bytes.
extension ObjectExtension on Object {
  /// Converts this object to a [Uint8List] containing its JSON-encoded representation.
  ///
  /// Returns the UTF-8 encoded bytes of the JSON string.
  Uint8List toJsonBytes() {
    final jsonString = jsonEncode(this);
    return Uint8List.fromList(utf8.encode(jsonString));
  }
}
