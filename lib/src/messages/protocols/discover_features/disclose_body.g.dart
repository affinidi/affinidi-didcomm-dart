// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disclose_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscloseBody _$DiscloseBodyFromJson(Map<String, dynamic> json) => DiscloseBody(
  disclosures: (json['disclosures'] as List<dynamic>)
      .map((e) => Disclosure.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DiscloseBodyToJson(DiscloseBody instance) =>
    <String, dynamic>{
      'disclosures': instance.disclosures.map((e) => e.toJson()).toList(),
    };
