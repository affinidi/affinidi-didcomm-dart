import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../../converters/base64_url_converter.dart';
import '../../curves/curve_type.dart';
import '../../messages/jwm/ephemeral_key_type.dart';

part 'ephemeral_key.g.dart';

@JsonSerializable()
class EphemeralKey {
  @JsonKey(name: 'kty')
  final EphemeralKeyType keyType;
  @JsonKey(name: 'crv')
  final CurveType curve;

  @Base64UrlConverter()
  final Uint8List x;

  @Base64UrlConverter()
  final Uint8List? y;

  EphemeralKey({
    required this.keyType,
    required this.curve,
    required this.x,
    this.y,
  });

  factory EphemeralKey.fromJson(Map<String, dynamic> json) =>
      _$EphemeralKeyFromJson(json);

  Map<String, dynamic> toJson() => _$EphemeralKeyToJson(this);
}
