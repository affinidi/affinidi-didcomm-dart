// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disclosure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Disclosure _$DisclosureFromJson(Map<String, dynamic> json) => Disclosure(
      id: json['id'] as String,
      featureType: json['feature-type'] as String,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$DisclosureToJson(Disclosure instance) =>
    <String, dynamic>{
      'feature-type': instance.featureType,
      'id': instance.id,
      if (instance.roles case final value?) 'roles': value,
    };
