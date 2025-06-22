import 'package:json_annotation/json_annotation.dart';

part 'jws_header.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class JwsHeader {
  // TODO: clarify with SSI why it is null here: https://github.com/affinidi/affinidi-ssi-dart/blob/main/lib/src/types.dart#L69
  @JsonKey(name: 'alg')
  final String algorithm;

  @JsonKey(name: 'crv')
  final String? curve;

  @JsonKey(name: 'typ')
  final String mimeType;

  JwsHeader({
    required this.algorithm,
    this.curve,
    required this.mimeType,
  });

  factory JwsHeader.fromJson(Map<String, dynamic> json) =>
      _$JwsHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$JwsHeaderToJson(this);
}
