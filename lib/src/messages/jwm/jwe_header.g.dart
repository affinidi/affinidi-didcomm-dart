// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwe_header.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JweHeader _$JweHeaderFromJson(Map<String, dynamic> json) => JweHeader(
  type: json['typ'] as String? ?? 'application/didcomm-encrypted+json',
  subjectKeyId: json['skid'] as String?,
  keyWrappingAlgorithm: $enumDecode(_$KeyWrappingAlgorithmEnumMap, json['alg']),
  encryptionAlgorithm: $enumDecode(_$EncryptionAlgorithmEnumMap, json['enc']),
  ephemeralKey: EphemeralKey.fromJson(json['epk'] as Map<String, dynamic>),
  agreementPartyUInfo: json['apu'] as String?,
  agreementPartyVInfo: json['apv'] as String?,
);

Map<String, dynamic> _$JweHeaderToJson(JweHeader instance) => <String, dynamic>{
  'typ': instance.type,
  'skid': instance.subjectKeyId,
  'alg': _$KeyWrappingAlgorithmEnumMap[instance.keyWrappingAlgorithm]!,
  'enc': _$EncryptionAlgorithmEnumMap[instance.encryptionAlgorithm]!,
  'epk': instance.ephemeralKey,
  'apu': instance.agreementPartyUInfo,
  'apv': instance.agreementPartyVInfo,
};

const _$KeyWrappingAlgorithmEnumMap = {
  KeyWrappingAlgorithm.ecdhES: 'ECDH-ES+A256KW',
  KeyWrappingAlgorithm.ecdh1PU: 'ECDH-1PU+A256KW',
};

const _$EncryptionAlgorithmEnumMap = {
  EncryptionAlgorithm.a256cbc: 'A256CBC-HS512',
  EncryptionAlgorithm.a256gcm: 'A256GCM',
};
