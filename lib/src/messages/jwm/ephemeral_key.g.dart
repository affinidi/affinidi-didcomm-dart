// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ephemeral_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EphemeralKey _$EphemeralKeyFromJson(Map<String, dynamic> json) => EphemeralKey(
  keyType: $enumDecode(_$EphemeralKeyTypeEnumMap, json['kty']),
  curve: $enumDecode(_$CurveTypeEnumMap, json['crv']),
  x: const Base64UrlConverter().fromJson(json['x'] as String),
  y: _$JsonConverterFromJson<String, Uint8List>(
    json['y'],
    const Base64UrlConverter().fromJson,
  ),
);

Map<String, dynamic> _$EphemeralKeyToJson(EphemeralKey instance) =>
    <String, dynamic>{
      'kty': _$EphemeralKeyTypeEnumMap[instance.keyType]!,
      'crv': _$CurveTypeEnumMap[instance.curve]!,
      'x': const Base64UrlConverter().toJson(instance.x),
      'y': _$JsonConverterToJson<String, Uint8List>(
        instance.y,
        const Base64UrlConverter().toJson,
      ),
    };

const _$EphemeralKeyTypeEnumMap = {
  EphemeralKeyType.ec: 'EC',
  EphemeralKeyType.okp: 'OKP',
};

const _$CurveTypeEnumMap = {
  CurveType.p256: 'P-256',
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
