// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ephemeral_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EphemeralKey _$EphemeralKeyFromJson(Map<String, dynamic> json) => EphemeralKey(
  keyType: json['kty'] as String,
  curve: json['crv'] as String,
  xCoordinate: json['x'] as String,
  yCoordinate: json['y'] as String,
);

Map<String, dynamic> _$EphemeralKeyToJson(EphemeralKey instance) =>
    <String, dynamic>{
      'kty': instance.keyType,
      'crv': instance.curve,
      'x': instance.xCoordinate,
      'y': instance.yCoordinate,
    };
