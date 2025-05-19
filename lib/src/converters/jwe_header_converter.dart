import 'dart:convert';

import 'package:didcomm/src/common/encoding.dart';
import 'package:json_annotation/json_annotation.dart';
import '../extensions/extensions.dart';
import '../messages/jwm/jwe_header.dart';

class JweHeaderConverter implements JsonConverter<JweHeader, String> {
  const JweHeaderConverter();

  @override
  JweHeader fromJson(String base64UrlInput) {
    final bytes = base64UrlDecodeWithPadding(base64UrlInput);
    final jsonString = ascii.decode(bytes);

    return JweHeader.fromJson(jsonDecode(jsonString));
  }

  @override
  String toJson(JweHeader object) =>
      base64UrlEncodeNoPadding(object.toJsonBytes());
}
