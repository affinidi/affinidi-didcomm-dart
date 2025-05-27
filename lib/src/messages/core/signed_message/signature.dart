import 'package:json_annotation/json_annotation.dart';
import '../encrypted_message/recipients/recipient_header.dart';

part 'signature.g.dart';

@JsonSerializable()
class Signature {
  final String protected;
  final String signature;
  final RecipientHeader header;

  Signature({
    required this.protected,
    required this.signature,
    required this.header,
  });

  factory Signature.fromJson(Map<String, dynamic> json) =>
      _$SignatureFromJson(json);

  Map<String, dynamic> toJson() => _$SignatureToJson(this);
}
