// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plaintext_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaintextMessage _$PlaintextMessageFromJson(Map<String, dynamic> json) =>
    PlaintextMessage(
      id: json['id'] as String,
      type: Uri.parse(json['type'] as String),
      from: json['from'] as String?,
      to: (json['to'] as List<dynamic>?)?.map((e) => e as String).toList(),
      threadId: json['thid'] as String?,
      parentThreadId: json['pthid'] as String?,
      createdTime: _$JsonConverterFromJson<int, DateTime>(
        json['created_time'],
        const EpochSecondsConverter().fromJson,
      ),
      expiresTime: _$JsonConverterFromJson<int, DateTime>(
        json['expires_time'],
        const EpochSecondsConverter().fromJson,
      ),
      body: json['body'] as Map<String, dynamic>?,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$PlaintextMessageToJson(PlaintextMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type.toString(),
      'from': instance.from,
      'to': instance.to,
      'thid': instance.threadId,
      'pthid': instance.parentThreadId,
      'created_time': _$JsonConverterToJson<int, DateTime>(
        instance.createdTime,
        const EpochSecondsConverter().toJson,
      ),
      'expires_time': _$JsonConverterToJson<int, DateTime>(
        instance.expiresTime,
        const EpochSecondsConverter().toJson,
      ),
      'body': instance.body,
      'attachments': instance.attachments,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
