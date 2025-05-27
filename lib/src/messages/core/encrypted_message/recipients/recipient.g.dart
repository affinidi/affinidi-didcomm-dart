// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recipient _$RecipientFromJson(Map<String, dynamic> json) => Recipient(
      encryptedKey:
          const Base64UrlConverter().fromJson(json['encrypted_key'] as String),
      header: RecipientHeader.fromJson(json['header'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RecipientToJson(Recipient instance) => <String, dynamic>{
      'encrypted_key': const Base64UrlConverter().toJson(instance.encryptedKey),
      'header': instance.header,
    };
