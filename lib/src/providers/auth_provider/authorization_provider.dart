import '../../../didcomm.dart';

/// An abstract provider for handling authorization and access tokens.
///
/// Implementations are responsible for generating and refreshing access tokens
/// as needed, based on expiration and minimum duration requirements.
abstract class AuthorizationProvider {
  AuthorizationTokens? _authenticationTokens;

  /// Returns valid authorization tokens, refreshing it if necessary.
  ///
  /// [minDuration] specifies the minimum required validity duration for the token.
  /// If the cached token expires before this duration, a new token is generated.
  ///
  /// Returns a [AuthorizationTokens] authorization tokens.
  Future<AuthorizationTokens> getAuthorizationTokens({
    Duration minDuration = const Duration(minutes: 3),
  }) async {
    final minDate = DateTime.now().toUtc().add(minDuration);

    if (_authenticationTokens != null &&
        _authenticationTokens!.accessExpiresAt.isAfter(minDate)) {
      return _authenticationTokens!;
    }

    _authenticationTokens = await generateTokens();
    return _authenticationTokens!;
  }

  /// Generates new authorization tokens.
  ///
  /// Implementations must provide the logic for obtaining fresh tokens.
  Future<AuthorizationTokens> generateTokens();
}
