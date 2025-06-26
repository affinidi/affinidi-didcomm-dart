import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../../../converters/base64_url_converter.dart';
import '../../../curves/curve_type.dart';
import 'ephemeral_key_type.dart';

part 'ephemeral_key.g.dart';

/// Represents an ephemeral public key used in JWE (JSON Web Encryption) messages.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class EphemeralKey {
  /// The key type (e.g., OKP, EC).
  @JsonKey(name: 'kty')
  final EphemeralKeyType keyType;

  /// The cryptographic curve used (e.g., Ed25519, P-256).
  @JsonKey(name: 'crv')
  final CurveType curve;

  /// The public key's x coordinate, base64url encoded.
  @Base64UrlConverter()
  final Uint8List x;

  /// The public key's y coordinate, base64url encoded (optional).
  @Base64UrlConverter()
  final Uint8List? y;

  /// Creates an [EphemeralKey] instance.
  EphemeralKey({
    required this.keyType,
    required this.curve,
    required this.x,
    this.y,
  });

  /// Creates an [EphemeralKey] from a JSON map.
  factory EphemeralKey.fromJson(Map<String, dynamic> json) =>
      _$EphemeralKeyFromJson(json);

  /// Converts this [EphemeralKey] to a JSON map.
  Map<String, dynamic> toJson() => _$EphemeralKeyToJson(this);
}
