class MissingKeyAgreementError extends Error {
  final String message;

  MissingKeyAgreementError([this.message = 'Missing key agreement']);

  @override
  String toString() {
    return 'MissingKeyAgreementError: $message';
  }
}
