import 'package:json_annotation/json_annotation.dart';

import '../../converters/epoch_seconds_converter.dart';

part 'authentication_tokens.g.dart';

/// Represents a set of authentication tokens, including access and refresh tokens,
/// along with their expiration times.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AuthenticationTokens {
  /// The access token used for authenticating API requests.
  @JsonKey(name: 'access_token')
  final String accessToken;

  /// The expiration time of the access token as a [DateTime] (UTC, seconds since epoch when serialized).
  @JsonKey(name: 'access_expires_at')
  @EpochSecondsConverter()
  final DateTime accessExpiresAt;

  /// The refresh token used to obtain a new access token.
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  /// The expiration time of the refresh token as a [DateTime] (UTC, seconds since epoch when serialized).
  @JsonKey(name: 'refresh_expires_at')
  @EpochSecondsConverter()
  final DateTime refreshExpiresAt;

  /// Creates an [AuthenticationTokens] instance.
  ///
  /// [accessToken] - The access token string.
  /// [accessExpiresAt] - The expiration time of the access token.
  /// [refreshToken] - The refresh token string.
  /// [refreshExpiresAt] - The expiration time of the refresh token.
  AuthenticationTokens({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  /// Creates an [AuthenticationTokens] instance from a JSON map.
  ///
  /// [json] - The JSON map to parse.
  factory AuthenticationTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationTokensFromJson(json);

  /// Converts this [AuthenticationTokens] instance to a JSON map.
  Map<String, dynamic> toJson() => _$AuthenticationTokensToJson(this);
}
