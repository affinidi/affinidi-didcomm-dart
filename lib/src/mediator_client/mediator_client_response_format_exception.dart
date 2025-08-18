import '../../didcomm.dart';

/// Exception thrown by [MediatorClient] for errors during mediator response parsing.
///
/// Provides raw messages in raw format.
class MediatorClientResponseFormatException implements Exception {
  /// The stringified raw response received by mediator.
  final String response;

  /// Creates a [MediatorClientResponseFormatException].
  ///
  /// The response is the original response returned by mediator.
  MediatorClientResponseFormatException(this.response);

  /// Returns a formatted string describing the mediator error, including status code and details.
  @override
  String toString() {
    return '''An error occured while parsing mediator response. Response: $response''';
  }
}
