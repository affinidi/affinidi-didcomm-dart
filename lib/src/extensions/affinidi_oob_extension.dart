import 'package:dio/dio.dart';

import '../../didcomm.dart';

// TODO: should be eventually moved to TDK
/// Extension for [MediatorClient] to support OOB messages on a mediator.
extension AffinidiOobExtension on MediatorClient {
  /// Creates an Out-of-Band (OOB) invitation and returns its identifier as a [String].
  ///
  /// This method initiates the OOB process, which is typically used for establishing
  /// connections or sharing information outside of a predefined communication channel.
  ///
  /// Returns a [Future] that completes with the OOB invitation identifier.
  Future<String> createOob(
    OutOfBandMessage message, {
    String? accessToken,
  }) async {
    final dio = mediatorDidDocument.toDio(
      mediatorServiceType: DidDocumentServiceType.didCommMessaging,
    );

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/oob',
        data: message,
        options: Options(headers: headers),
      );

      return (response.data!['data'] as Map<String, dynamic>)['_oobid']
          as String;
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }
}
