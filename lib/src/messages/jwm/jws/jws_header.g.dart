// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jws_header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JwsHeader _$JwsHeaderFromJson(Map<String, dynamic> json) => JwsHeader(
      algorithm: json['alg'] as String,
      curve: json['crv'] as String?,
      mimeType: json['typ'] as String,
    );

Map<String, dynamic> _$JwsHeaderToJson(JwsHeader instance) => <String, dynamic>{
      'alg': instance.algorithm,
      if (instance.curve case final value?) 'crv': value,
      'typ': instance.mimeType,
    };
