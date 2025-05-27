// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encrypted_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EncryptedMessage _$EncryptedMessageFromJson(
  Map<String, dynamic> json,
) => EncryptedMessage(
  cipherText: const Base64UrlConverter().fromJson(json['ciphertext'] as String),
  protected: const JweHeaderConverter().fromJson(json['protected'] as String),
  recipients:
      (json['recipients'] as List<dynamic>)
          .map((e) => Recipient.fromJson(e as Map<String, dynamic>))
          .toList(),
  authenticationTag: const Base64UrlConverter().fromJson(json['tag'] as String),
  initializationVector: const Base64UrlConverter().fromJson(
    json['iv'] as String,
  ),
);

Map<String, dynamic> _$EncryptedMessageToJson(EncryptedMessage instance) =>
    <String, dynamic>{
      'ciphertext': const Base64UrlConverter().toJson(instance.cipherText),
      'protected': const JweHeaderConverter().toJson(instance.protected),
      'recipients': instance.recipients,
      'tag': const Base64UrlConverter().toJson(instance.authenticationTag),
      'iv': const Base64UrlConverter().toJson(instance.initializationVector),
    };
