import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../converters/base64_url_converter.dart';
import '../curves/curve_type.dart';

part 'jwk.g.dart';

@JsonSerializable()
class Jwk {
  // it is optional in spec, but required in our library and many others
  @JsonKey(name: 'kid')
  final String keyId;
  @JsonKey(name: 'kty')
  final String keyType;
  @JsonKey(name: 'use')
  final String? publicKeyUse;
  @JsonKey(name: 'key_ops')
  final List<String>? keyOperations;
  @JsonKey(name: 'alg')
  final String? algorithm;
  @JsonKey(name: 'x5u')
  final String? x509Url;
  @JsonKey(name: 'x5c')
  final List<String>? x509CertificateChain;
  @JsonKey(name: 'x5t')
  final String? x509Thumbprint;
  @JsonKey(name: 'x5t#S256')
  final String? x509ThumbprintS256;

  // EC key fields
  @JsonKey(name: 'crv')
  final CurveType? curve;
  @Base64UrlConverter()
  final Uint8List? x;
  @Base64UrlConverter()
  final Uint8List? y;
  @Base64UrlConverter()
  final String? d;

  // RSA key fields
  final String? n;
  final String? e;
  final String? p;
  final String? q;
  final String? dp;
  final String? dq;
  final String? qi;
  final List<Map<String, dynamic>>? oth;

  // Octet sequence key field
  final String? k;

  Jwk({
    required this.keyId,
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

  factory Jwk.fromJson(Map<String, dynamic> json) => _$JwkFromJson(json);
  Map<String, dynamic> toJson() => _$JwkToJson(this);
}
