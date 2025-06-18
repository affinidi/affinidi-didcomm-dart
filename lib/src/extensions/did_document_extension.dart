import 'package:collection/collection.dart';
import 'package:didcomm/src/curves/curve_type.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/io.dart';
import 'package:ssi/ssi.dart' hide Jwk;

import '../common/did.dart';
import '../common/did_document_service_type.dart';
import '../jwks/jwk.dart';
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

  List<String> getKeyIdsWithCommonType({
    required Wallet wallet,
    required List<DidDocument> otherDidDocuments,
  }) {
    final ownCurves = Set<CurveType>.from(
      keyAgreement
          .map(
            (keyAgreement) => getCurveFromKeyAgreement(keyAgreement),
          )
          .where(
            (type) => type != null,
          ),
    );

    final matchedCurves = ownCurves.where(
      (ownCurve) => otherDidDocuments.every(
        (doc) => doc.keyAgreement.any(
          (keyAgreement) => getCurveFromKeyAgreement(keyAgreement) == ownCurve,
        ),
      ),
    );

    return matchedCurves.map((curve) {
      final jwkKeyId = keyAgreement
          .firstWhere(
            (keyAgreement) => getCurveFromKeyAgreement(keyAgreement) == curve,
          )
          .id;

      final keyId = wallet.getKeyIdByJwkId(jwkKeyId);

      if (keyId == null) {
        throw Exception(
          'Can not find mapping between JWK kid and key ID in the wallet',
        );
      }

      return keyId;
    }).toList();
  }

  CurveType? getCurveFromKeyAgreement(VerificationMethod keyAgreement) {
    final jwk = Jwk.fromJson(keyAgreement.asJwk().toJson());
    return jwk.curve;
  }
}
