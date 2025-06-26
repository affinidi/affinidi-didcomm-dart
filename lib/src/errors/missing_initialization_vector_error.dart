/// Error thrown when an initialization vector is missing from a cryptographic operation,
/// such as during decryption of a DIDComm message.
class MissingInitializationVectorError extends Error {
  /// The error message describing the missing initialization vector.
  final String message;

  /// Constructs a [MissingInitializationVectorError].
  ///
  /// [message]: Optional custom error message (default: 'Missing initialization vector').
  MissingInitializationVectorError(
      [this.message = 'Missing initialization vector']);

  /// Returns a string representation of the error.
  @override
  String toString() {
    return 'MissingInitializationVectorError: $message';
  }
}
