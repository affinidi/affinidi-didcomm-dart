import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import '../../../converters/base64_url_converter.dart';
import '../../../converters/jws_header_converter.dart';
import '../../jwm.dart';

part 'signature.g.dart';

@JsonSerializable(includeIfNull: false)
class Signature {
  @JwsHeaderConverter()
  final JwsHeader protected;
  @Base64UrlConverter()
  final Uint8List signature;
  final SignatureHeader header;

  Signature({
    required this.protected,
    required this.signature,
    required this.header,
  });

  factory Signature.fromJson(Map<String, dynamic> json) =>
      _$SignatureFromJson(json);

  Map<String, dynamic> toJson() => _$SignatureToJson(this);
}
