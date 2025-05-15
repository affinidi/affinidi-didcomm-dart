// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwe_header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JweHeader _$JweHeaderFromJson(Map<String, dynamic> json) => JweHeader(
  type: json['typ'] as String? ?? 'application/didcomm-encrypted+json',
  subjectKeyId: json['skid'] as String?,
  algorithm: json['alg'] as String,
  encryptionAlgorithm: json['enc'] as String,
  keyWrapAlgorithm: json['keyWrapAlg'] as String,
  ephemeralKey: EphemeralKey.fromJson(json['epk'] as Map<String, dynamic>),
  agreementPartyUInfo: json['apu'] as String?,
  agreementPartyVInfo: json['apv'] as String?,
);

Map<String, dynamic> _$JweHeaderToJson(JweHeader instance) => <String, dynamic>{
  'typ': instance.type,
  'skid': instance.subjectKeyId,
  'alg': instance.algorithm,
  'enc': instance.encryptionAlgorithm,
  'keyWrapAlg': instance.keyWrapAlgorithm,
  'epk': instance.ephemeralKey,
  'apu': instance.agreementPartyUInfo,
  'apv': instance.agreementPartyVInfo,
};
