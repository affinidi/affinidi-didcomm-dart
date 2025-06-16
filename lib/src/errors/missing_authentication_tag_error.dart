class MissingAuthenticationTag extends Error {
  final String message;

  MissingAuthenticationTag([this.message = 'Missing authentication tag']);

  @override
  String toString() {
    return 'MissingAuthenticationTag: $message';
  }
}
