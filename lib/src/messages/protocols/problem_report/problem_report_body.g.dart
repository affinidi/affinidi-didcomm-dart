// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_report_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProblemReportBody _$ProblemReportBodyFromJson(Map<String, dynamic> json) =>
    ProblemReportBody(
      code: const ProblemCodeConverter().fromJson(json['code'] as String),
      comment: json['comment'] as String?,
      arguments:
          (json['args'] as List<dynamic>?)?.map((e) => e as String).toList(),
      escalateTo: json['escalate_to'] as String?,
    );

Map<String, dynamic> _$ProblemReportBodyToJson(ProblemReportBody instance) =>
    <String, dynamic>{
      'code': const ProblemCodeConverter().toJson(instance.code),
      if (instance.comment case final value?) 'comment': value,
      if (instance.arguments case final value?) 'args': value,
      if (instance.escalateTo case final value?) 'escalate_to': value,
    };
