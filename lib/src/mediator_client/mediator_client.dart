import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import 'mediator_service_type.dart';

class MediatorClient {
  final DidDocument didDocument;
  final Dio _dioForMessaging;
  final Dio _dioForAuthentication;

  MediatorClient({
    required this.didDocument,
  })  : _dioForMessaging = _createDio(
          didDocument: didDocument,
          mediatorServiceType: MediatorServiceType.didCommMessaging.value,
        ),
        _dioForAuthentication = _createDio(
          didDocument: didDocument,
          mediatorServiceType: MediatorServiceType.authentication.value,
        );

  static Future<MediatorClient> fromDidDocumentUri(Uri didDocumentUrl) async {
    final response = await Dio().getUri(didDocumentUrl);

    return MediatorClient(
      didDocument: DidDocument.fromJson(response.data),
    );
  }

  Future<String> authenticate({required String did}) async {
    final response = await _dioForAuthentication.post(
      '/challenge',
      data: {'did': did},
    );

    final challenge = response.data!['data']['challenge'];
    print(challenge);

    return '';
  }

  static Dio _createDio({
    required DidDocument didDocument,
    required String mediatorServiceType,
  }) {
    final service = didDocument.service.firstWhere(
      (service) => service.type == mediatorServiceType,
      orElse: () => throw ArgumentError(
        'DID Document does not have a service with type $mediatorServiceType',
        'didDocument',
      ),
    );

    final serviceEndpoint = service.serviceEndpoint.firstWhere(
      (endpoint) => endpoint.uri.startsWith('https://'),
      orElse: () => throw ArgumentError(
        'Can not find https endpoint in $mediatorServiceType service',
        'didDocument',
      ),
    );

    return Dio(BaseOptions(
      baseUrl: serviceEndpoint.uri,
      contentType: 'application/json',
    ));
  }
}
