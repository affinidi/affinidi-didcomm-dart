import 'dart:convert';
import 'dart:typed_data';

/// Decodes a base64 string (with or without padding) to a UTF-8 string.
///
/// [data]: The base64-encoded string.
/// Returns the decoded UTF-8 string.
String base64DecodeToUtf8(String data) {
  final withPadding = _addPaddingForBase64(data);
  return utf8.decode(base64Decode(withPadding));
}

/// Encodes bytes as a base64url string without padding.
///
/// [bytes]: The bytes to encode.
/// Returns the base64url-encoded string without padding.
String base64UrlEncodeNoPadding(List<int> bytes) {
  return _removePaddingFromBase64(base64UrlEncode(bytes));
}

/// Decodes a base64url string (with or without padding) to a [Uint8List].
///
/// [data]: The base64url-encoded string.
/// Returns the decoded bytes as [Uint8List].
Uint8List base64UrlDecodeWithPadding(String data) {
  return base64Url.decode(_addPaddingForBase64(data));
}

/// Adds padding to a base64 string if necessary.
///
/// [base64Input]: The base64 string to pad.
/// Returns the padded base64 string.
String _addPaddingForBase64(String base64Input) {
  final paddingNeeded = (4 - base64Input.length % 4) % 4;
  return base64Input + '=' * paddingNeeded;
}

/// Removes padding from a base64 string.
///
/// [base64Input]: The base64 string to remove padding from.
/// Returns the base64 string without padding.
String _removePaddingFromBase64(String base64Input) {
  var endIndex = base64Input.length;

  while (endIndex > 0 && base64Input[endIndex - 1] == '=') {
    endIndex--;
  }

  return base64Input.substring(0, endIndex);
}
