// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signature.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Signature _$SignatureFromJson(Map<String, dynamic> json) => Signature(
      protected: json['protected'] as String,
      signature: json['signature'] as String,
      header: RecipientHeader.fromJson(json['header'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SignatureToJson(Signature instance) => <String, dynamic>{
      'protected': instance.protected,
      'signature': instance.signature,
      'header': instance.header,
    };
