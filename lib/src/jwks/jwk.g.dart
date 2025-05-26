// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Jwk _$JwkFromJson(Map<String, dynamic> json) => Jwk(
  keyId: json['kid'] as String?,
  keyType: json['kty'] as String,
  publicKeyUse: json['use'] as String?,
  keyOperations:
      (json['key_ops'] as List<dynamic>?)?.map((e) => e as String).toList(),
  algorithm: json['alg'] as String?,
  x509Url: json['x5u'] as String?,
  x509CertificateChain:
      (json['x5c'] as List<dynamic>?)?.map((e) => e as String).toList(),
  x509Thumbprint: json['x5t'] as String?,
  x509ThumbprintS256: json['x5t#S256'] as String?,
  curve: $enumDecodeNullable(_$CurveTypeEnumMap, json['crv']),
  x: _$JsonConverterFromJson<String, Uint8List>(
    json['x'],
    const Base64UrlConverter().fromJson,
  ),
  y: _$JsonConverterFromJson<String, Uint8List>(
    json['y'],
    const Base64UrlConverter().fromJson,
  ),
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
  'kid': instance.keyId,
  'kty': instance.keyType,
  'use': instance.publicKeyUse,
  'key_ops': instance.keyOperations,
  'alg': instance.algorithm,
  'x5u': instance.x509Url,
  'x5c': instance.x509CertificateChain,
  'x5t': instance.x509Thumbprint,
  'x5t#S256': instance.x509ThumbprintS256,
  'crv': _$CurveTypeEnumMap[instance.curve],
  'x': _$JsonConverterToJson<String, Uint8List>(
    instance.x,
    const Base64UrlConverter().toJson,
  ),
  'y': _$JsonConverterToJson<String, Uint8List>(
    instance.y,
    const Base64UrlConverter().toJson,
  ),
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

const _$CurveTypeEnumMap = {
  CurveType.p256: 'P-256',
  CurveType.p384: 'P-384',
  CurveType.p521: 'P-521',
  CurveType.secp256k1: 'secp256k1',
  CurveType.x25519: 'X25519',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
