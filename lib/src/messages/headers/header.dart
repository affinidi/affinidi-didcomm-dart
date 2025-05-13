import 'package:json_annotation/json_annotation.dart';

part 'header.g.dart';

@JsonSerializable()
class Header {
  @JsonKey(name: 'kid')
  final String keyId;

  Header({required this.keyId});

  factory Header.fromJson(Map<String, dynamic> json) =>
      _$RecipientHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$RecipientHeaderToJson(this);
}
