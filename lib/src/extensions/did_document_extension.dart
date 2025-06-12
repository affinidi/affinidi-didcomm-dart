import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/io.dart';
import 'package:ssi/ssi.dart';

import '../mediator_client/mediator_service_type.dart';

enum DidCommServiceType {
  didCommMessaging('DIDCommMessaging');

  final String value;
  const DidCommServiceType(this.value);
}

extension DidDocumentExtension on DidDocument {
  Dio toDio({required MediatorServiceType mediatorServiceType}) {
    final serviceType = mediatorServiceType.value;

    final service = this.service.firstWhere(
          (service) => service.type == serviceType,
          orElse: () => throw ArgumentError(
            'DID Document does not have a service with type $serviceType',
            'didDocument',
          ),
        );

    final serviceEndpoint = service.serviceEndpoint.firstWhere(
      (endpoint) => endpoint.uri.startsWith('https://'),
      orElse: () => throw ArgumentError(
        'Can not find https endpoint in $serviceType service',
        'didDocument',
      ),
    );

    return Dio(BaseOptions(
      baseUrl: serviceEndpoint.uri,
      contentType: 'application/json',
    ));
  }

  IOWebSocketChannel toWebSocketChannel({String? accessToken}) {
    final serviceType = MediatorServiceType.didCommMessaging.value;

    final service = this.service.firstWhere(
          (service) => service.type == serviceType,
          orElse: () => throw ArgumentError(
            'DID Document does not have a service with type $serviceType',
            'didDocument',
          ),
        );

    final serviceEndpoint = service.serviceEndpoint.firstWhere(
      (endpoint) => endpoint.uri.startsWith('wss://'),
      orElse: () => throw ArgumentError(
        'Can not find wss endpoint in $serviceType service',
        'didDocument',
      ),
    );

    return IOWebSocketChannel.connect(
      Uri.parse(serviceEndpoint.uri),
      // Uri.parse('wss://echo.websocket.events'),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    );
  }

  List<ServiceEndpoint> getMediators() {
    return service
        .where((item) => item.type == DidCommServiceType.didCommMessaging.value)
        .toList();
  }

  ServiceEndpoint? getMediatorById(String mediatorId) {
    return getMediators().firstWhereOrNull((item) => item.id == mediatorId);
  }

  void copyMediatorsFromDidDocument(DidDocument didDocument) {
    final mediatorServices = didDocument.getMediators();
    service.addAll(mediatorServices);
  }
}
