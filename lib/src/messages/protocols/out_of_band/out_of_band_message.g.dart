// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'out_of_band_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutOfBandMessage _$OutOfBandMessageFromJson(Map<String, dynamic> json) =>
    OutOfBandMessage(
      id: json['id'] as String,
      from: json['from'] as String,
      goal: json['goal'] as String,
      goalCode: json['goalCode'] as String,
      body: json['body'] as Map<String, dynamic>?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OutOfBandMessageToJson(OutOfBandMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from': instance.from,
      'goal': instance.goal,
      'goalCode': instance.goalCode,
      if (instance.body case final value?) 'body': value,
      if (instance.attachments?.map((e) => e.toJson()).toList()
          case final value?)
        'attachments': value,
    };
