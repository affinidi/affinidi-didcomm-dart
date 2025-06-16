class MissingInitializationVectorError extends Error {
  final String message;

  MissingInitializationVectorError(
      [this.message = 'Missing initialization vector']);

  @override
  String toString() {
    return 'MissingInitializationVectorError: $message';
  }
}
