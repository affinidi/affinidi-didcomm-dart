import '../../../didcomm.dart';

abstract class AuthorizationProvider {
  AuthorizationTokens? _authenticationTokens;

  Future<String> getAccessToken({
    Duration minDuration = const Duration(minutes: 3),
  }) async {
    final minDate = DateTime.now().toUtc().add(minDuration);

    if (_authenticationTokens != null &&
        _authenticationTokens!.accessExpiresAt.isAfter(minDate)) {
      return _authenticationTokens!.accessToken;
    }

    _authenticationTokens = await generateTokens();
    return _authenticationTokens!.accessToken;
  }

  Future<AuthorizationTokens> generateTokens();
}
