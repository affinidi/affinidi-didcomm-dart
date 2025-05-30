import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import '../extensions/extensions.dart';
import '../messages/didcomm_message.dart';
import 'mediator_service_type.dart';

class MediatorClient {
  final DidDocument didDocument;
  final Dio _dio;

  MediatorClient({
    required this.didDocument,
  }) : _dio = didDocument.toDio(
          mediatorServiceType: MediatorServiceType.didCommMessaging,
        );

  static Future<MediatorClient> fromDidDocumentUri(Uri didDocumentUrl) async {
    final response = await Dio().getUri(didDocumentUrl);

    return MediatorClient(
      didDocument: DidDocument.fromJson(response.data),
    );
  }

  Future<void> send({
    required DidcommMessage message,
    String? accessToken,
  }) async {
    // TODO: create exception to wrap errors

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    await _dio.post(
      '/inbound',
      data: message,
      options: Options(headers: headers),
    );
  }
}
