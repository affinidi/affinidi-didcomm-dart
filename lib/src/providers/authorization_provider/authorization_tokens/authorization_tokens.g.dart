// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authorization_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorizationTokens _$AuthorizationTokensFromJson(Map<String, dynamic> json) =>
    AuthorizationTokens(
      accessToken: json['access_token'] as String,
      accessExpiresAt: const EpochSecondsConverter()
          .fromJson((json['access_expires_at'] as num).toInt()),
      refreshToken: json['refresh_token'] as String,
      refreshExpiresAt: const EpochSecondsConverter()
          .fromJson((json['refresh_expires_at'] as num).toInt()),
    );

Map<String, dynamic> _$AuthorizationTokensToJson(
        AuthorizationTokens instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'access_expires_at':
          const EpochSecondsConverter().toJson(instance.accessExpiresAt),
      'refresh_token': instance.refreshToken,
      'refresh_expires_at':
          const EpochSecondsConverter().toJson(instance.refreshExpiresAt),
    };
