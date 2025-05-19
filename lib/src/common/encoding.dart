import 'dart:convert';
import 'dart:typed_data';

String base64DecodeToUtf8(String data) {
  final withPadding = _addPaddingForBase64(data);
  return utf8.decode(base64Decode(withPadding));
}

String base64UrlEncodeNoPadding(List<int> bytes) {
  return _removePaddingFromBase64(base64UrlEncode(bytes));
}

Uint8List base64UrlDecodeWithPadding(String data) {
  return base64Url.decode(_addPaddingForBase64(data));
}

String _addPaddingForBase64(String base64Input) {
  final paddingNeeded = (4 - base64Input.length % 4) % 4;
  return base64Input + '=' * paddingNeeded;
}

String _removePaddingFromBase64(String base64Input) {
  var endIndex = base64Input.length;

  while (endIndex > 0 && base64Input[endIndex - 1] == '=') {
    endIndex--;
  }

  return base64Input.substring(0, endIndex);
}
