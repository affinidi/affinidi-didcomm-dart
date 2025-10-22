// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentData _$AttachmentDataFromJson(Map<String, dynamic> json) =>
    AttachmentData(
      jws: json['jws'] as String?,
      hash: json['hash'] as String?,
      links: (json['links'] as List<dynamic>?)
          ?.map((e) => Uri.parse(e as String))
          .toList(),
      base64: json['base64'] as String?,
      json: json['json'] as String?,
    );

Map<String, dynamic> _$AttachmentDataToJson(AttachmentData instance) =>
    <String, dynamic>{
      'jws': ?instance.jws,
      'hash': ?instance.hash,
      'links': ?instance.links?.map((e) => e.toString()).toList(),
      'base64': ?instance.base64,
      'json': ?instance.json,
    };
