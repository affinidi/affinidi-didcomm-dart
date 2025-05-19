import 'dart:typed_data';

import 'package:didcomm/src/common/encoding.dart';
import 'package:json_annotation/json_annotation.dart';

class Base64UrlConverter implements JsonConverter<Uint8List, String> {
  const Base64UrlConverter();

  @override
  Uint8List fromJson(String base64Url) => base64UrlDecodeWithPadding(base64Url);

  @override
  String toJson(Uint8List object) => base64UrlEncodeNoPadding(object);
}
