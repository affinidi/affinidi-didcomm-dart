import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../../../../converters/base64_url_converter.dart';
import 'recipient_header.dart';

part 'recipient.g.dart';

/// Represents a recipient in a JWE (JSON Web Encryption) message.
///
/// Contains the encrypted key and the associated header for the recipient.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Recipient {
  /// The encrypted key for the recipient, encoded as base64url.
  @JsonKey(name: 'encrypted_key')
  @Base64UrlConverter()
  final Uint8List encryptedKey;

  /// The header containing recipient-specific parameters.
  final RecipientHeader header;

  /// Creates a [Recipient] with the given [encryptedKey] and [header].
  Recipient({required this.encryptedKey, required this.header});

  /// Creates a [Recipient] instance from a JSON [json] map.
  factory Recipient.fromJson(Map<String, dynamic> json) =>
      _$RecipientFromJson(json);

  /// Converts this [Recipient] instance to a JSON map.
  Map<String, dynamic> toJson() => _$RecipientToJson(this);
}
