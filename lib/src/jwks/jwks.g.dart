// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Jwks _$JwksFromJson(Map<String, dynamic> json) => Jwks(
  keys:
      (json['keys'] as List<dynamic>)
          .map((e) => Jwk.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$JwksToJson(Jwks instance) => <String, dynamic>{
  'keys': instance.keys,
};
