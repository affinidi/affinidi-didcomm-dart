// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Jwk _$JwkFromJson(Map<String, dynamic> json) => Jwk(
  keyType: json['kty'] as String,
  publicKeyUse: json['use'] as String?,
  keyOperations:
      (json['key_ops'] as List<dynamic>?)?.map((e) => e as String).toList(),
  algorithm: json['alg'] as String?,
  keyId: json['kid'] as String?,
  x509Url: json['x5u'] as String?,
  x509CertificateChain:
      (json['x5c'] as List<dynamic>?)?.map((e) => e as String).toList(),
  x509Thumbprint: json['x5t'] as String?,
  x509ThumbprintS256: json['x5t#S256'] as String?,
  curve: json['crv'] as String?,
  x: json['x'] as String?,
  y: json['y'] as String?,
  d: json['d'] as String?,
  n: json['n'] as String?,
  e: json['e'] as String?,
  p: json['p'] as String?,
  q: json['q'] as String?,
  dp: json['dp'] as String?,
  dq: json['dq'] as String?,
  qi: json['qi'] as String?,
  oth:
      (json['oth'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
  k: json['k'] as String?,
);

Map<String, dynamic> _$JwkToJson(Jwk instance) => <String, dynamic>{
  'kty': instance.keyType,
  'use': instance.publicKeyUse,
  'key_ops': instance.keyOperations,
  'alg': instance.algorithm,
  'kid': instance.keyId,
  'x5u': instance.x509Url,
  'x5c': instance.x509CertificateChain,
  'x5t': instance.x509Thumbprint,
  'x5t#S256': instance.x509ThumbprintS256,
  'crv': instance.curve,
  'x': instance.x,
  'y': instance.y,
  'd': instance.d,
  'n': instance.n,
  'e': instance.e,
  'p': instance.p,
  'q': instance.q,
  'dp': instance.dp,
  'dq': instance.dq,
  'qi': instance.qi,
  'oth': instance.oth,
  'k': instance.k,
};
