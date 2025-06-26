/// Error thrown when a key agreement in a DID is missing from a cryptographic operation,
/// such as during DIDComm message encryption or decryption.
// TODO: consider to rename like DidMatchingKeyAgreementError
class MissingKeyAgreementError extends Error {
  /// The error message describing the missing key agreement.
  final String message;

  /// Constructs a [MissingKeyAgreementError].
  ///
  /// [message]: Optional custom error message (default: 'Missing key agreement').
  MissingKeyAgreementError([this.message = 'Missing key agreement']);

  /// Returns a string representation of the error.
  @override
  String toString() {
    return 'MissingKeyAgreementError: $message';
  }
}
