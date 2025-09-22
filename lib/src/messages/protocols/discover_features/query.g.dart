// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Query _$QueryFromJson(Map<String, dynamic> json) => Query(
      featureType: json['featureType'] as String,
      match: json['match'] as String,
    );

Map<String, dynamic> _$QueryToJson(Query instance) => <String, dynamic>{
      'featureType': instance.featureType,
      'match': instance.match,
    };
