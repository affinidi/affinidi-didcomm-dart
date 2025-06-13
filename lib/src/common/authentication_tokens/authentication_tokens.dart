import 'package:json_annotation/json_annotation.dart';

import '../../converters/epoch_seconds_converter.dart';

part 'authentication_tokens.g.dart';

// TODO: should be eventually moved to TDK
@JsonSerializable()
class AuthenticationTokens {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'access_expires_at')
  @EpochSecondsConverter()
  final DateTime accessExpiresAt;

  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @JsonKey(name: 'refresh_expires_at')
  @EpochSecondsConverter()
  final DateTime refreshExpiresAt;

  AuthenticationTokens({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  factory AuthenticationTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationTokensFromJson(json);

  Map<String, dynamic> toJson() => _$AuthenticationTokensToJson(this);
}
