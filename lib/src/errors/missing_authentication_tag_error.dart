/// Error thrown when an authentication tag is missing from a cryptographic operation,
/// such as during decryption of a DIDComm message.
class MissingAuthenticationTag extends Error {
  /// The error message describing the missing authentication tag.
  final String message;

  /// Constructs a [MissingAuthenticationTag] error.
  ///
  /// [message]: Optional custom error message (default: 'Missing authentication tag').
  MissingAuthenticationTag([this.message = 'Missing authentication tag']);

  /// Returns a string representation of the error.
  @override
  String toString() {
    return 'MissingAuthenticationTag: $message';
  }
}
