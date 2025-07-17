// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueryBody _$QueryBodyFromJson(Map<String, dynamic> json) => QueryBody(
      queries: (json['queries'] as List<dynamic>)
          .map((e) => Query.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QueryBodyToJson(QueryBody instance) => <String, dynamic>{
      'queries': instance.queries.map((e) => e.toJson()).toList(),
    };
