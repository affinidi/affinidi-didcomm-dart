import 'package:json_annotation/json_annotation.dart';

part 'jwk.g.dart';

@JsonSerializable()
class Jwk {
  @JsonKey(name: 'kty')
  final String keyType;
  @JsonKey(name: 'use')
  final String? publicKeyUse;
  @JsonKey(name: 'key_ops')
  final List<String>? keyOperations;
  @JsonKey(name: 'alg')
  final String? algorithm;
  @JsonKey(name: 'kid')
  final String? keyId;
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
  final String? curve;
  final String? x;
  final String? y;
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
    required this.keyType,
    this.publicKeyUse,
    this.keyOperations,
    this.algorithm,
    this.keyId,
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
