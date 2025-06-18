import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/io.dart';
import 'package:ssi/ssi.dart';

import '../common/did.dart';
import '../common/did_document_service_type.dart';
import 'wallet_extension.dart';

extension DidDocumentExtension on DidDocument {
  Dio toDio({required DidDocumentServiceType mediatorServiceType}) {
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
    final serviceType = DidDocumentServiceType.didCommMessaging.value;

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
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    );
  }

  List<ServiceEndpoint> getServicesByType(DidDocumentServiceType serviceType) {
    return service.where((item) => item.type == serviceType.value).toList();
  }

  ServiceEndpoint? getServiceById(String serviceId) {
    return service.firstWhereOrNull((item) => item.id == serviceId);
  }

  ServiceEndpoint? getServiceByDid(String serviceDid) {
    return service.firstWhereOrNull(
      (item) => getDidFromId(item.id) == serviceDid,
    );
  }

  ServiceEndpoint? getFirstServiceByType(DidDocumentServiceType serviceType) {
    return service.firstWhereOrNull((item) => item.type == serviceType.value);
  }

  String? getFirstServiceDidByType(DidDocumentServiceType serviceType) {
    final service = getFirstServiceByType(serviceType);
    return service != null ? getDidFromId(service.id) : null;
  }

  void copyServicesByTypeFromDidDocument(
    DidDocumentServiceType serviceType,
    DidDocument didDocument,
  ) {
    final services = didDocument.getServicesByType(serviceType);
    service.addAll(services);
  }

  Future<void> copyServicesByTypeFromResolvedDid(
    DidDocumentServiceType serviceType,
    String did,
  ) async {
    final didDocument = await UniversalDIDResolver.resolve(did);
    copyServicesByTypeFromDidDocument(serviceType, didDocument);
  }

  List<String> getKeyIdsMatchedByType({
    required Wallet wallet,
    required List<DidDocument> otherDidDocuments,
  }) {
    // TODO: this is a mock. Add implementation in the next MR
    return wallet.getKeyIds();
  }
}
