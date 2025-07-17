// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disclosure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Disclosure _$DisclosureFromJson(Map<String, dynamic> json) => Disclosure(
      id: json['id'] as String,
      featureType: $enumDecode(_$FeatureTypeEnumMap, json['feature-type'],
          unknownValue: FeatureType.unknown),
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$DisclosureToJson(Disclosure instance) =>
    <String, dynamic>{
      'id': instance.id,
      'feature-type': _$FeatureTypeEnumMap[instance.featureType]!,
      if (instance.roles case final value?) 'roles': value,
    };

const _$FeatureTypeEnumMap = {
  FeatureType.protocol: 'protocol',
  FeatureType.goalCode: 'goal-code',
  FeatureType.header: 'header',
  FeatureType.unknown: 'unknown',
};
