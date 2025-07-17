// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disclose_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscloseMessage _$DiscloseMessageFromJson(Map<String, dynamic> json) =>
    DiscloseMessage(
      id: json['id'] as String,
      parentThreadId: json['pthid'] as String?,
      body: DiscloseBody.fromJson(json['body'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DiscloseMessageToJson(DiscloseMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      if (instance.parentThreadId case final value?) 'pthid': value,
      if (instance.body case final value?) 'body': value,
    };
