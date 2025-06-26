import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../common/encoding.dart';

/// A [JsonConverter] for encoding and decoding [Uint8List] as base64url strings.
///
/// This converter is used to serialize and deserialize binary data in DIDComm messages.
class Base64UrlConverter implements JsonConverter<Uint8List, String> {
  /// Creates a [Base64UrlConverter].
  const Base64UrlConverter();

  /// Decodes a [Uint8List] from a base64url-encoded string.
  ///
  /// [base64Url]: The base64url-encoded string.
  /// Returns the decoded [Uint8List].
  @override
  Uint8List fromJson(String base64Url) => base64UrlDecodeWithPadding(base64Url);

  /// Encodes a [Uint8List] as a base64url-encoded string.
  ///
  /// [object]: The [Uint8List] to encode.
  /// Returns the base64url-encoded string.
  @override
  String toJson(Uint8List object) => base64UrlEncodeNoPadding(object);
}
