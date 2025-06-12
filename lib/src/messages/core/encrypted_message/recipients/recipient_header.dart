import 'package:json_annotation/json_annotation.dart';

part 'recipient_header.g.dart';

@JsonSerializable(includeIfNull: false)
class RecipientHeader {
  @JsonKey(name: 'kid')
  final String keyId;

  RecipientHeader({required this.keyId});

  factory RecipientHeader.fromJson(Map<String, dynamic> json) =>
      _$RecipientHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$RecipientHeaderToJson(this);
}
