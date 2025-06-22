// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signature.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Signature _$SignatureFromJson(Map<String, dynamic> json) => Signature(
      protected:
          const JwsHeaderConverter().fromJson(json['protected'] as String),
      signature:
          const Base64UrlConverter().fromJson(json['signature'] as String),
      header: SignatureHeader.fromJson(json['header'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SignatureToJson(Signature instance) => <String, dynamic>{
      'protected': const JwsHeaderConverter().toJson(instance.protected),
      'signature': const Base64UrlConverter().toJson(instance.signature),
      'header': instance.header.toJson(),
    };
