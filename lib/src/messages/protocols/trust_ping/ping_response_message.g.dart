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
      createdTime: _$JsonConverterFromJson<int, DateTime>(
        json['created_time'],
        const EpochSecondsConverter().fromJson,
      ),
      expiresTime: _$JsonConverterFromJson<int, DateTime>(
        json['expires_time'],
        const EpochSecondsConverter().fromJson,
      ),
      parentThreadId: json['pthid'] as String?,
      acknowledged: (json['ack'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      pleaseAcknowledge: (json['please_ack'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PingResponseMessageToJson(
  PingResponseMessage instance,
) => <String, dynamic>{
  'id': instance.id,
  'from': ?instance.from,
  'to': ?instance.to,
  'thid': ?instance.threadId,
  'pthid': ?instance.parentThreadId,
  'created_time': ?_$JsonConverterToJson<int, DateTime>(
    instance.createdTime,
    const EpochSecondsConverter().toJson,
  ),
  'expires_time': ?_$JsonConverterToJson<int, DateTime>(
    instance.expiresTime,
    const EpochSecondsConverter().toJson,
  ),
  'please_ack': ?instance.pleaseAcknowledge,
  'ack': ?instance.acknowledged,
  'attachments': ?instance.attachments?.map((e) => e.toJson()).toList(),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
