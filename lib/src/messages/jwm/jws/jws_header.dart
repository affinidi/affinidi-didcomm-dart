import 'package:json_annotation/json_annotation.dart';

part 'jws_header.g.dart';

@JsonSerializable()
class JwsHeader {
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
