// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_pickup_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessagePickupMessage _$MessagePickupMessageFromJson(
        Map<String, dynamic> json) =>
    MessagePickupMessage(
      id: json['id'] as String,
      to: (json['to'] as List<dynamic>?)?.map((e) => e as String).toList(),
      from: json['from'] as String?,
      type: Uri.parse(json['type'] as String),
      body: json['body'] as Map<String, dynamic>?,
      createdTime: _$JsonConverterFromJson<int, DateTime>(
          json['created_time'], const EpochSecondsConverter().fromJson),
      expiresTime: _$JsonConverterFromJson<int, DateTime>(
          json['expires_time'], const EpochSecondsConverter().fromJson),
      threadId: json['thid'] as String?,
      parentThreadId: json['pthid'] as String?,
      acknowledged:
          (json['ack'] as List<dynamic>?)?.map((e) => e as String).toList(),
      pleaseAcknowledge: (json['please_ack'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      returnRoute: json['return_route'] as String? ?? 'all',
    );

Map<String, dynamic> _$MessagePickupMessageToJson(
        MessagePickupMessage instance) =>
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
      if (instance.pleaseAcknowledge case final value?) 'please_ack': value,
      if (instance.acknowledged case final value?) 'ack': value,
      if (instance.body case final value?) 'body': value,
      if (instance.attachments?.map((e) => e.toJson()).toList()
          case final value?)
        'attachments': value,
      'return_route': instance.returnRoute,
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
