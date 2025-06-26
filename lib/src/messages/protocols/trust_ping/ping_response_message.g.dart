// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ping_response_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PingResponseMessage _$PingResponseMessageFromJson(Map<String, dynamic> json) =>
    PingResponseMessage(
      id: json['id'] as String,
      threadId: json['thid'],
      to: (json['to'] as List<dynamic>?)?.map((e) => e as String).toList(),
      from: json['from'] as String?,
    );

Map<String, dynamic> _$PingResponseMessageToJson(
        PingResponseMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      if (instance.from case final value?) 'from': value,
      if (instance.to case final value?) 'to': value,
      if (instance.threadId case final value?) 'thid': value,
    };
