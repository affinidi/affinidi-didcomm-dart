// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueryMessage _$QueryMessageFromJson(Map<String, dynamic> json) => QueryMessage(
      id: json['id'] as String,
      body: QueryBody.fromJson(json['body'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QueryMessageToJson(QueryMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      if (instance.body case final value?) 'body': value,
    };
