// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signed_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignedMessage _$SignedMessageFromJson(Map<String, dynamic> json) =>
    SignedMessage(
      payload: json['payload'] as String,
      signatures:
          (json['signatures'] as List<dynamic>)
              .map((e) => Signature.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$SignedMessageToJson(SignedMessage instance) =>
    <String, dynamic>{
      'payload': instance.payload,
      'signatures': instance.signatures,
    };
