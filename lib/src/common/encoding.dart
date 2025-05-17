import 'dart:convert';

String base64DecodeToUtf8(String data) {
  final withPadding = addPaddingToBase64(data);
  return utf8.decode(base64Decode(withPadding));
}

String base64UrlEncodeNoPadding(List<int> bytes) {
  return removePaddingFromBase64(base64UrlEncode(bytes));
}

String addPaddingToBase64(String base64Input) {
  final paddingNeeded = (4 - base64Input.length % 4) % 4;
  return base64Input + '=' * paddingNeeded;
}

String removePaddingFromBase64(String base64Input) {
  var endIndex = base64Input.length;

  while (endIndex > 0 && base64Input[endIndex - 1] == '=') {
    endIndex--;
  }

  return base64Input.substring(0, endIndex);
}
