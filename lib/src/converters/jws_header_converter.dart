import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import '../common/encoding.dart';
import '../extensions/extensions.dart';
import '../messages/jwm.dart';

/// A [JsonConverter] for encoding and decoding [JwsHeader] objects as base64url strings.
///
/// This converter is used to serialize and deserialize JWS protected headers in DIDComm messages.
class JwsHeaderConverter implements JsonConverter<JwsHeader, String> {
  /// Creates a [JwsHeaderConverter].
  const JwsHeaderConverter();

  /// Decodes a [JwsHeader] from a base64url-encoded JSON string.
  ///
  /// [base64UrlInput]: The base64url-encoded string representing the JWS header.
  /// Returns the decoded [JwsHeader] object.
  @override
  JwsHeader fromJson(String base64UrlInput) {
    final bytes = base64UrlDecodeWithPadding(base64UrlInput);
    final jsonString = ascii.decode(bytes);

    return JwsHeader.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Encodes a [JwsHeader] as a base64url-encoded JSON string.
  ///
  /// [object]: The [JwsHeader] to encode.
  /// Returns the base64url-encoded string.
  @override
  String toJson(JwsHeader object) =>
      base64UrlEncodeNoPadding(object.toJsonBytes());
}
