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
          json['x'], const Base64UrlConverter().fromJson),
      y: _$JsonConverterFromJson<String, Uint8List>(
          json['y'], const Base64UrlConverter().fromJson),
      d: json['d'] as String?,
      n: json['n'] as String?,
      e: json['e'] as String?,
      p: json['p'] as String?,
      q: json['q'] as String?,
      dp: json['dp'] as String?,
      dq: json['dq'] as String?,
      qi: json['qi'] as String?,
      oth: (json['oth'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      k: json['k'] as String?,
    );

Map<String, dynamic> _$JwkToJson(Jwk instance) => <String, dynamic>{
      if (instance.keyId case final value?) 'kid': value,
      'kty': instance.keyType,
      if (instance.publicKeyUse case final value?) 'use': value,
      if (instance.keyOperations case final value?) 'key_ops': value,
      if (instance.algorithm case final value?) 'alg': value,
      if (instance.x509Url case final value?) 'x5u': value,
      if (instance.x509CertificateChain case final value?) 'x5c': value,
      if (instance.x509Thumbprint case final value?) 'x5t': value,
      if (instance.x509ThumbprintS256 case final value?) 'x5t#S256': value,
      if (_$CurveTypeEnumMap[instance.curve] case final value?) 'crv': value,
      if (_$JsonConverterToJson<String, Uint8List>(
              instance.x, const Base64UrlConverter().toJson)
          case final value?)
        'x': value,
      if (_$JsonConverterToJson<String, Uint8List>(
              instance.y, const Base64UrlConverter().toJson)
          case final value?)
        'y': value,
      if (instance.d case final value?) 'd': value,
      if (instance.n case final value?) 'n': value,
      if (instance.e case final value?) 'e': value,
      if (instance.p case final value?) 'p': value,
      if (instance.q case final value?) 'q': value,
      if (instance.dp case final value?) 'dp': value,
      if (instance.dq case final value?) 'dq': value,
      if (instance.qi case final value?) 'qi': value,
      if (instance.oth case final value?) 'oth': value,
      if (instance.k case final value?) 'k': value,
    };

const _$CurveTypeEnumMap = {
  CurveType.p256: 'P-256',
  CurveType.secp256k1: 'secp256k1',
  CurveType.x25519: 'X25519',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
