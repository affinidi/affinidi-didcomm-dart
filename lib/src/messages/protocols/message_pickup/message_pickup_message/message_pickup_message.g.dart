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
      expiresTime: _$JsonConverterFromJson<int, DateTime>(
          json['expires_time'], const EpochSecondsConverter().fromJson),
      returnRoute: json['return_route'] as String? ?? 'all',
    );

Map<String, dynamic> _$MessagePickupMessageToJson(
        MessagePickupMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type.toString(),
      if (instance.from case final value?) 'from': value,
      if (instance.to case final value?) 'to': value,
      if (_$JsonConverterToJson<int, DateTime>(
              instance.expiresTime, const EpochSecondsConverter().toJson)
          case final value?)
        'expires_time': value,
      if (instance.body case final value?) 'body': value,
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
