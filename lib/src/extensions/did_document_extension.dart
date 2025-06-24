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

  ServiceEndpoint? getFirstServiceByType(DidDocumentServiceType serviceType) {
    return service.firstWhereOrNull((item) => item.type == serviceType.value);
  }

  String? getFirstMediatorDid() {
    final service = getFirstServiceByType(
      DidDocumentServiceType.didCommMessaging,
    );

    return service != null
        ? getDidFromId(service.serviceEndpoint.first.uri)
        : null;
  }

  void addMediatorReferencesFromDidDocument(
    DidDocument didDocument,
  ) {
    final mediators = didDocument.getServicesByType(
      DidDocumentServiceType.didCommMessaging,
    );

    final servicesToAdd = mediators.map(
      (service) => ServiceEndpoint(
        id: service.id.replaceFirst(getDidFromId(service.id), id),
        type: service.type,
        serviceEndpoint: [
          // TODO: revisit after ServiceEndpoint update in Dart SSI. only uri is needed
          DIDCommServiceEndpoint(
            accept: [],
            routingKeys: [],
            uri: getDidFromId(service.id),
          )
        ],
      ),
    );

    service.addAll(servicesToAdd);
  }

  Future<void> addMediatorReferencesFromResolvedDid(
    String did,
  ) async {
    final didDocument = await UniversalDIDResolver.resolve(did);
    addMediatorReferencesFromDidDocument(didDocument);
  }

  List<String> matchKeysInKeyAgreement({
    required Wallet wallet,
    required List<DidDocument> otherDidDocuments,
  }) {
    final ownCurves = Set<CurveType>.from(
      keyAgreement
          .map(
            (keyAgreement) => getCurve(keyAgreement),
          )
          .where(
            (type) => type != null,
          ),
    );

    final matchedCurves = ownCurves.where(
      (ownCurve) => otherDidDocuments.every(
        (doc) => doc.keyAgreement.any(
          (keyAgreement) => getCurve(keyAgreement) == ownCurve,
        ),
      ),
    );

    return matchedCurves.map((curve) {
      final didKeyId = keyAgreement
          .firstWhere(
            (keyAgreement) => getCurve(keyAgreement) == curve,
          )
          .id;

      final keyId = wallet.getKeyIdByDidKeyId(didKeyId);

      if (keyId == null) {
        throw Exception(
          'Can not find mapping between JWK kid and key ID in the wallet',
        );
      }

      return keyId;
    }).toList();
  }

  CurveType? getCurve(VerificationMethod keyAgreement) {
    final jwk = Jwk.fromJson(keyAgreement.asJwk().toJson());
    return jwk.curve;
  }
}
