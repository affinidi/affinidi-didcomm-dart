import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../../../../converters/base64_url_converter.dart';
import 'recipient_header.dart';

part 'recipient.g.dart';

@JsonSerializable(includeIfNull: false)
class Recipient {
  @JsonKey(name: 'encrypted_key')
  @Base64UrlConverter()
  final Uint8List encryptedKey;

  final RecipientHeader header;

  Recipient({required this.encryptedKey, required this.header});

  factory Recipient.fromJson(Map<String, dynamic> json) =>
      _$RecipientFromJson(json);

  Map<String, dynamic> toJson() => _$RecipientToJson(this);
}
