// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_report_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProblemReportMessage _$ProblemReportMessageFromJson(
        Map<String, dynamic> json) =>
    ProblemReportMessage(
      id: json['id'] as String,
      parentThreadId: json['pthid'] as String?,
      acknowledged:
          (json['ack'] as List<dynamic>?)?.map((e) => e as String).toList(),
      body: ProblemReportBody.fromJson(json['body'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProblemReportMessageToJson(
        ProblemReportMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      if (instance.parentThreadId case final value?) 'pthid': value,
      if (instance.acknowledged case final value?) 'ack': value,
      if (instance.body case final value?) 'body': value,
    };
