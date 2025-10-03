import '../../../didcomm.dart';

/// An abstract provider for handling authorization and access tokens.
///
/// Implementations are responsible for generating and refreshing access tokens
/// as needed, based on expiration and minimum duration requirements.
abstract class AuthorizationProvider {
  AuthorizationTokens? _authenticationTokens;

  /// Returns a valid access token, refreshing it if necessary.
  ///
  /// [minDuration] specifies the minimum required validity duration for the token.
  /// If the cached token expires before this duration, a new token is generated.
  ///
  /// Returns a [String] access token.
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

  /// Generates new authorization tokens.
  ///
  /// Implementations must provide the logic for obtaining fresh tokens.
  Future<AuthorizationTokens> generateTokens();
}
