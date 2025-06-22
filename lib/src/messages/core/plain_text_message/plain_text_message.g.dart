// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plain_text_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlainTextMessage _$PlainTextMessageFromJson(Map<String, dynamic> json) =>
    PlainTextMessage(
      id: json['id'] as String,
      type: Uri.parse(json['type'] as String),
      from: json['from'] as String?,
      to: (json['to'] as List<dynamic>?)?.map((e) => e as String).toList(),
      threadId: json['thid'] as String?,
      parentThreadId: json['pthid'] as String?,
      createdTime: _$JsonConverterFromJson<int, DateTime>(
          json['created_time'], const EpochSecondsConverter().fromJson),
      expiresTime: _$JsonConverterFromJson<int, DateTime>(
          json['expires_time'], const EpochSecondsConverter().fromJson),
      body: json['body'] as Map<String, dynamic>?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlainTextMessageToJson(PlainTextMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type.toString(),
      if (instance.from case final value?) 'from': value,
      if (instance.to case final value?) 'to': value,
      if (instance.threadId case final value?) 'thid': value,
      if (instance.parentThreadId case final value?) 'pthid': value,
      if (_$JsonConverterToJson<int, DateTime>(
              instance.createdTime, const EpochSecondsConverter().toJson)
          case final value?)
        'created_time': value,
      if (_$JsonConverterToJson<int, DateTime>(
              instance.expiresTime, const EpochSecondsConverter().toJson)
          case final value?)
        'expires_time': value,
      if (instance.body case final value?) 'body': value,
      if (instance.attachments?.map((e) => e.toJson()).toList()
          case final value?)
        'attachments': value,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
