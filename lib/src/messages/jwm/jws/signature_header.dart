import 'package:json_annotation/json_annotation.dart';

part 'signature_header.g.dart';

@JsonSerializable(includeIfNull: false)
class SignatureHeader {
  @JsonKey(name: 'kid')
  final String keyId;

  SignatureHeader({required this.keyId});

  factory SignatureHeader.fromJson(Map<String, dynamic> json) =>
      _$SignatureHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$SignatureHeaderToJson(this);
}
