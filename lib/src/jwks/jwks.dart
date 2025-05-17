import 'package:json_annotation/json_annotation.dart';
import 'jwk.dart';

part 'jwks.g.dart';

@JsonSerializable()
class Jwks {
  final List<Jwk> keys;

  Jwks({required this.keys});

  factory Jwks.fromJson(Map<String, dynamic> json) => _$JwksFromJson(json);
  Map<String, dynamic> toJson() => _$JwksToJson(this);
}
