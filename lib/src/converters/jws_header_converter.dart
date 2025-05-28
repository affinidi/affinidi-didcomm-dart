import 'dart:convert';

import 'package:didcomm/src/common/encoding.dart';
import 'package:json_annotation/json_annotation.dart';
import '../extensions/extensions.dart';
import '../messages/jwm.dart';

class JwsHeaderConverter implements JsonConverter<JwsHeader, String> {
  const JwsHeaderConverter();

  @override
  JwsHeader fromJson(String base64UrlInput) {
    final bytes = base64UrlDecodeWithPadding(base64UrlInput);
    final jsonString = ascii.decode(bytes);

    return JwsHeader.fromJson(jsonDecode(jsonString));
  }

  @override
  String toJson(JwsHeader object) =>
      base64UrlEncodeNoPadding(object.toJsonBytes());
}
