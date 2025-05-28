// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signature_header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignatureHeader _$SignatureHeaderFromJson(Map<String, dynamic> json) =>
    SignatureHeader(
      keyId: json['kid'] as String,
    );

Map<String, dynamic> _$SignatureHeaderToJson(SignatureHeader instance) =>
    <String, dynamic>{
      'kid': instance.keyId,
    };
