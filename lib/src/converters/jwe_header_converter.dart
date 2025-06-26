import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import '../common/encoding.dart';
import '../extensions/extensions.dart';
import '../messages/jwm.dart';

/// A [JsonConverter] for encoding and decoding [JweHeader] objects as base64url strings.
///
/// This converter is used to serialize and deserialize JWE protected headers in DIDComm messages.
class JweHeaderConverter implements JsonConverter<JweHeader, String> {
  /// Creates a [JweHeaderConverter].
  const JweHeaderConverter();

  /// Decodes a [JweHeader] from a base64url-encoded JSON string.
  ///
  /// [base64UrlInput]: The base64url-encoded string representing the JWE header.
  /// Returns the decoded [JweHeader] object.
  @override
  JweHeader fromJson(String base64UrlInput) {
    final bytes = base64UrlDecodeWithPadding(base64UrlInput);
    final jsonString = ascii.decode(bytes);

    return JweHeader.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Encodes a [JweHeader] as a base64url-encoded JSON string.
  ///
  /// [object]: The [JweHeader] to encode.
  /// Returns the base64url-encoded string.
  @override
  String toJson(JweHeader object) =>
      base64UrlEncodeNoPadding(object.toJsonBytes());
}
