import 'package:json_annotation/json_annotation.dart';
import '../headers/header.dart';

part 'recipient.g.dart';

@JsonSerializable()
class Recipient {
  @JsonKey(name: 'encrypted_key')
  final String encryptedKey;

  final Header header;

  Recipient({required this.encryptedKey, required this.header});

  factory Recipient.fromJson(Map<String, dynamic> json) =>
      _$RecipientFromJson(json);

  Map<String, dynamic> toJson() => _$RecipientToJson(this);
}
