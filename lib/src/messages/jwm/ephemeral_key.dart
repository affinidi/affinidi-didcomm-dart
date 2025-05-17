import 'package:didcomm/src/messages/jwm/ephemeral_key_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ephemeral_key.g.dart';

@JsonSerializable()
class EphemeralKey {
  @JsonKey(name: 'kty')
  final EphemeralKeyType keyType;
  @JsonKey(name: 'crv')
  final String curve;

  final String x;
  final String? y;

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
