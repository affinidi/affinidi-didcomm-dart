import 'package:json_annotation/json_annotation.dart';

part 'ephemeral_key.g.dart';

@JsonSerializable()
class EphemeralKey {
  @JsonKey(name: 'kty')
  final String keyType;

  @JsonKey(name: 'crv')
  final String curve;

  @JsonKey(name: 'x')
  final String xCoordinate;

  @JsonKey(name: 'y')
  final String yCoordinate;

  EphemeralKey({
    required this.keyType,
    required this.curve,
    required this.xCoordinate,
    required this.yCoordinate,
  });

  factory EphemeralKey.fromJson(Map<String, dynamic> json) =>
      _$EphemeralKeyFromJson(json);

  Map<String, dynamic> toJson() => _$EphemeralKeyToJson(this);
}
