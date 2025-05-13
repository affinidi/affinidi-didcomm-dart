// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encrypted_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EncryptedMessage _$EncryptedMessageFromJson(Map<String, dynamic> json) =>
    EncryptedMessage(
      cipherText: json['ciphertext'] as String,
      protected: json['protected'] as String,
      recipients:
          (json['recipients'] as List<dynamic>)
              .map((e) => Recipient.fromJson(e as Map<String, dynamic>))
              .toList(),
      tag: json['tag'] as String,
      initializationVector: json['iv'] as String,
    );

Map<String, dynamic> _$EncryptedMessageToJson(EncryptedMessage instance) =>
    <String, dynamic>{
      'ciphertext': instance.cipherText,
      'protected': instance.protected,
      'recipients': instance.recipients,
      'tag': instance.tag,
      'iv': instance.initializationVector,
    };
