// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attachment _$AttachmentFromJson(Map<String, dynamic> json) => Attachment(
      id: json['id'] as String?,
      description: json['description'] as String?,
      filename: json['filename'] as String?,
      mediaType: json['media_type'] as String?,
      format: json['format'] as String?,
      lastModifiedTime: _$JsonConverterFromJson<int, DateTime>(
          json['lastmod_time'], const EpochSecondsConverter().fromJson),
      data: json['data'] == null
          ? null
          : AttachmentData.fromJson(json['data'] as Map<String, dynamic>),
      byteCount: (json['byte_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AttachmentToJson(Attachment instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      if (instance.description case final value?) 'description': value,
      if (instance.filename case final value?) 'filename': value,
      if (instance.mediaType case final value?) 'media_type': value,
      if (instance.format case final value?) 'format': value,
      if (_$JsonConverterToJson<int, DateTime>(
              instance.lastModifiedTime, const EpochSecondsConverter().toJson)
          case final value?)
        'lastmod_time': value,
      if (instance.data?.toJson() case final value?) 'data': value,
      if (instance.byteCount case final value?) 'byte_count': value,
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
