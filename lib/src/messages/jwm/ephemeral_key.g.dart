// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ephemeral_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EphemeralKey _$EphemeralKeyFromJson(Map<String, dynamic> json) => EphemeralKey(
  keyType: $enumDecode(_$EphemeralKeyTypeEnumMap, json['kty']),
  curve: $enumDecode(_$CurveTypeEnumMap, json['crv']),
  x: json['x'] as String,
  y: json['y'] as String?,
);

Map<String, dynamic> _$EphemeralKeyToJson(EphemeralKey instance) =>
    <String, dynamic>{
      'kty': _$EphemeralKeyTypeEnumMap[instance.keyType]!,
      'crv': _$CurveTypeEnumMap[instance.curve]!,
      'x': instance.x,
      'y': instance.y,
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
