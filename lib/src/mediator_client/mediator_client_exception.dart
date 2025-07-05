import 'package:dio/dio.dart';

import '../../didcomm.dart';

/// Exception thrown by [MediatorClient] for errors during mediator operations.
///
/// Wraps a [DioException] and provides additional context and formatting for mediator-specific errors.
class MediatorClientException extends DioException {
  /// The composed error message extracted from the inner [DioException].
  final String innerMessage;

  /// Creates a [MediatorClientException] by wrapping an existing [DioException].
  ///
  /// The [innerException] is the original DioException thrown during mediator communication.
  MediatorClientException({required DioException innerException})
      : innerMessage = _composeMessage(innerException),
        super(
          requestOptions: innerException.requestOptions,
          error: innerException.error,
          message: innerException.message,
          response: innerException.response,
          stackTrace: innerException.stackTrace,
          type: innerException.type,
        );

  /// Returns a formatted string describing the mediator error, including status code and details.
  @override
  String toString() {
    return 'An error while calling mediator. Status code: ${response?.statusCode}. $innerMessage';
  }

  static String _composeMessage(DioException exception) {
    final data = exception.response?.data;

    if (data is String) {
      return data;
    }

    return (data as Map<String, dynamic>)
        .entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('. ');
  }
}
