import 'package:json_annotation/json_annotation.dart';
import 'ephemeral_key.dart';

part 'jwe_header.g.dart';

@JsonSerializable()
class JweHeader {
  @JsonKey(name: 'typ')
  final String type;

  @JsonKey(name: 'skid')
  final String? subjectKeyId;

  @JsonKey(name: 'alg')
  final String algorithm;

  @JsonKey(name: 'enc')
  final String encryptionAlgorithm;

  @JsonKey(name: 'keyWrapAlg')
  final String keyWrapAlgorithm;

  @JsonKey(name: 'epk')
  final EphemeralKey ephemeralKey;

  @JsonKey(name: 'apu')
  final String? agreementPartyUInfo;

  @JsonKey(name: 'apv')
  final String? agreementPartyVInfo;

  JweHeader({
    this.type = 'application/didcomm-encrypted+json',
    this.subjectKeyId,
    required this.algorithm,
    required this.encryptionAlgorithm,
    required this.keyWrapAlgorithm,
    required this.ephemeralKey,
    this.agreementPartyUInfo,
    required this.agreementPartyVInfo,
  });

  factory JweHeader.fromJson(Map<String, dynamic> json) =>
      _$JweHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$JweHeaderToJson(this);
}
