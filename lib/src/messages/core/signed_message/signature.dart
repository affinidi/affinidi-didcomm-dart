import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import '../../../converters/base64_url_converter.dart';
import '../../jwm.dart';

part 'signature.g.dart';

/// Represents a JWS (JSON Web Signature) signature structure as used in DIDComm messages.
///
/// See [DIDComm Messaging Spec, DIDComm Signed Messages](DIDComm Signed Messages)
/// for details on the structure and semantics of each field.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Signature {
  /// The protected JWS header, base64url-encoded.
  ///
  /// Contains cryptographic and metadata parameters for the signature.
  final String protected;

  /// The signature value, base64url-encoded.
  @Base64UrlConverter()
  final Uint8List signature;

  /// The unprotected JWS header, containing additional signature metadata.
  final SignatureHeader header;

  /// Constructs a [Signature] object.
  ///
  /// [protected]: The protected JWS header.
  /// [signature]: The signature value as bytes.
  /// [header]: The unprotected JWS header.
  Signature({
    required this.protected,
    required this.signature,
    required this.header,
  });

  /// Creates a [Signature] from a JSON map.
  ///
  /// [json]: The JSON map representing the signature.
  factory Signature.fromJson(Map<String, dynamic> json) =>
      _$SignatureFromJson(json);

  /// Converts this [Signature] to a JSON map.
  Map<String, dynamic> toJson() => _$SignatureToJson(this);
}
