import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../converters/base64_url_converter.dart';
import '../curves/curve_type.dart';

part 'jwk.g.dart';

/// Represents a JSON Web Key (JWK) as defined in RFC 7517.
/// Supports EC, RSA, and octet sequence keys.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Jwk {
  /// Key ID. Used to uniquely identify the key.
  @JsonKey(name: 'kid')
  final String? keyId;

  /// Key type (e.g., "EC", "RSA", "oct").
  @JsonKey(name: 'kty')
  final String keyType;

  /// Public key use (e.g., "sig" for signature or "enc" for encryption).
  @JsonKey(name: 'use')
  final String? publicKeyUse;

  /// Operations for which the key is intended (e.g., ["sign", "verify"]).
  @JsonKey(name: 'key_ops')
  final List<String>? keyOperations;

  /// Algorithm intended for use with the key (e.g., "ES256").
  @JsonKey(name: 'alg')
  final String? algorithm;

  /// X.509 URL. A URL that refers to a resource for the X.509 public key certificate or certificate chain.
  @JsonKey(name: 'x5u')
  final String? x509Url;

  /// X.509 certificate chain. The certificate or certificate chain.
  @JsonKey(name: 'x5c')
  final List<String>? x509CertificateChain;

  /// X.509 certificate SHA-1 thumbprint.
  @JsonKey(name: 'x5t')
  final String? x509Thumbprint;

  /// X.509 certificate SHA-256 thumbprint.
  @JsonKey(name: 'x5t#S256')
  final String? x509ThumbprintS256;

  // EC key fields
  /// Elliptic curve name (e.g., "P-256").
  @JsonKey(name: 'crv')
  final CurveType? curve;

  /// X coordinate for EC keys, base64url encoded.
  @Base64UrlConverter()
  final Uint8List? x;

  /// Y coordinate for EC keys, base64url encoded.
  @Base64UrlConverter()
  final Uint8List? y;

  /// Private key value for EC keys, base64url encoded.
  @Base64UrlConverter()
  final String? d;

  // RSA key fields
  /// RSA modulus value, base64url encoded.
  final String? n;

  /// RSA public exponent value, base64url encoded.
  final String? e;

  /// RSA secret prime factor p, base64url encoded.
  final String? p;

  /// RSA secret prime factor q, base64url encoded.
  final String? q;

  /// RSA secret exponent dp, base64url encoded.
  final String? dp;

  /// RSA secret exponent dq, base64url encoded.
  final String? dq;

  /// RSA secret coefficient qi, base64url encoded.
  final String? qi;

  /// RSA other primes info.
  final List<Map<String, dynamic>>? oth;

  // Octet sequence key field
  /// Symmetric key value, base64url encoded.
  final String? k;

  /// Constructs a [Jwk] instance.
  ///
  /// [keyId] Key ID. Used to uniquely identify the key.
  /// [keyType] Key type (e.g., "EC", "RSA", "oct"). Required.
  /// [publicKeyUse] Public key use (e.g., "sig" for signature or "enc" for encryption).
  /// [keyOperations] Operations for which the key is intended (e.g., ["sign", "verify"]).
  /// [algorithm] Algorithm intended for use with the key (e.g., "ES256").
  /// [x509Url] X.509 URL for the public key certificate or certificate chain.
  /// [x509CertificateChain] X.509 certificate chain.
  /// [x509Thumbprint] X.509 certificate SHA-1 thumbprint.
  /// [x509ThumbprintS256] X.509 certificate SHA-256 thumbprint.
  /// [curve] Elliptic curve name (e.g., "P-256").
  /// [x] X coordinate for EC keys, base64url encoded.
  /// [y] Y coordinate for EC keys, base64url encoded.
  /// [d] Private key value for EC keys, base64url encoded.
  /// [n] RSA modulus value, base64url encoded.
  /// [e] RSA public exponent value, base64url encoded.
  /// [p] RSA secret prime factor p, base64url encoded.
  /// [q] RSA secret prime factor q, base64url encoded.
  /// [dp] RSA secret exponent dp, base64url encoded.
  /// [dq] RSA secret exponent dq, base64url encoded.
  /// [qi] RSA secret coefficient qi, base64url encoded.
  /// [oth] RSA other primes info.
  /// [k] Symmetric key value, base64url encoded.
  Jwk({
    this.keyId,
    required this.keyType,
    this.publicKeyUse,
    this.keyOperations,
    this.algorithm,
    this.x509Url,
    this.x509CertificateChain,
    this.x509Thumbprint,
    this.x509ThumbprintS256,
    this.curve,
    this.x,
    this.y,
    this.d,
    this.n,
    this.e,
    this.p,
    this.q,
    this.dp,
    this.dq,
    this.qi,
    this.oth,
    this.k,
  });

  /// Creates a [Jwk] instance from a JSON map.
  ///
  /// [json] The JSON map representing the JWK.
  factory Jwk.fromJson(Map<String, dynamic> json) => _$JwkFromJson(json);

  /// Converts this [Jwk] instance to a JSON map.
  ///
  /// Returns a JSON map representing this JWK.
  Map<String, dynamic> toJson() => _$JwkToJson(this);
}
