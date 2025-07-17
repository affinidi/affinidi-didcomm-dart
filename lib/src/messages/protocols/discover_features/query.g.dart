// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Query _$QueryFromJson(Map<String, dynamic> json) => Query(
      featureType: $enumDecode(_$FeatureTypeEnumMap, json['feature-type'],
          unknownValue: FeatureType.unknown),
      match: json['match'] as String,
    );

Map<String, dynamic> _$QueryToJson(Query instance) => <String, dynamic>{
      'feature-type': _$FeatureTypeEnumMap[instance.featureType]!,
      'match': instance.match,
    };

const _$FeatureTypeEnumMap = {
  FeatureType.protocol: 'protocol',
  FeatureType.goalCode: 'goal-code',
  FeatureType.header: 'header',
  FeatureType.unknown: 'unknown',
};
