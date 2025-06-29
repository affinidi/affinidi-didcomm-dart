import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart' hide Jwk;
import 'package:web_socket_channel/io.dart';

import '../common/did.dart';
import '../common/did_document_service_type.dart';
import '../curves/curve_type.dart';
import '../jwks/jwk.dart';
import 'extensions.dart';

/// Extension methods for [DidDocument] to support DIDComm-specific operations,
/// such as extracting endpoints, creating transport clients, and key matching.
extension DidDocumentExtension on DidDocument {
  /// Creates a [Dio] HTTP client for the given [mediatorServiceType] endpoint in this DID Document.
  ///
  /// [mediatorServiceType]: The type of service to use as the HTTP endpoint.
  /// Throws [ArgumentError] if no matching service or HTTPS endpoint is found.
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

  /// Creates a [IOWebSocketChannel] for the `didcomm-messaging` service endpoint in this DID Document.
  ///
  /// [accessToken]: Optional access token to include in the WebSocket headers.
  /// Throws [ArgumentError] if no matching service or WSS endpoint is found.
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

  /// Returns all [ServiceEndpoint]s of the given [serviceType] in this DID Document.
  List<ServiceEndpoint> getServicesByType(DidDocumentServiceType serviceType) {
    return service.where((item) => item.type == serviceType.value).toList();
  }

  /// Returns the first [ServiceEndpoint] of the given [serviceType], or null if not found.
  ServiceEndpoint? getFirstServiceByType(DidDocumentServiceType serviceType) {
    return service.firstWhereOrNull((item) => item.type == serviceType.value);
  }

  /// Returns the first mediator DID from the `didcomm-messaging` service, or null if not found.
  String? getFirstMediatorDid() {
    final service = getFirstServiceByType(
      DidDocumentServiceType.didCommMessaging,
    );

    return service != null
        ? getDidFromId(service.serviceEndpoint.first.uri)
        : null;
  }

  /// Adds all mediators from another [didDocument] to this DID Document's services.
  ///
  /// [didDocument]: The DID Document from which to add mediators.
  void addMediatorsFromDidDocument(
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

  /// Resolves a DID and adds all mediators from the resolved DID Document to this DID Document's services.
  ///
  /// [did]: The DID to resolve and add mediators from.
  Future<void> addMediatorsFromResolvedDid(
    String did,
  ) async {
    final didDocument = await UniversalDIDResolver.resolve(did);
    addMediatorsFromDidDocument(didDocument);
  }

  /// Matches and returns key IDs in this DID Document's key agreement section that are compatible with all [otherDidDocuments].
  ///
  /// [wallet]: The wallet to use for key ID lookups.
  /// [otherDidDocuments]: The other DID Documents to match key agreement curves with.
  /// Throws if no compatible key is found in the wallet.
  List<String> matchKeysInKeyAgreement({
    required Wallet wallet,
    required List<DidDocument> otherDidDocuments,
  }) {
    final ownCurves = Set<CurveType>.from(
      keyAgreement.map(_getCurve).where(
            (type) => type != null,
          ),
    );

    final matchedCurves = ownCurves.where(
      (ownCurve) => otherDidDocuments.every(
        (doc) => doc.keyAgreement.any(
          (keyAgreement) => _getCurve(keyAgreement) == ownCurve,
        ),
      ),
    );

    return matchedCurves.map((curve) {
      final didKeyId = keyAgreement
          .firstWhere(
            (keyAgreement) => _getCurve(keyAgreement) == curve,
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
}

/// Extension methods for a list of [DidDocument]s to support finding common key types for key agreement.
extension DidDocumentsExtension on List<DidDocument> {
  /// Returns a list of [KeyType]s that are supported by all DID Documents in this list for key agreement.
  ///
  /// The method works by:
  /// - Extracting the set of curves from each DID Document's key agreement section.
  /// - Finding the intersection of all these sets (i.e., curves supported by all documents).
  /// - Mapping each common curve to its corresponding [KeyType].
  ///
  /// Returns an empty list if there are no common key types or if the list is empty.
  List<KeyType> getCommonKeyTypesInKeyAgreements() {
    if (isEmpty) return [];

    final commonCurves = map(
      (doc) => doc.keyAgreement.map(_getCurve).whereType<CurveType>().toSet(),
    ).reduce((a, b) => a.intersection(b));

    return commonCurves.map((curve) => curve.asKeyType()).toList();
  }
}

CurveType? _getCurve(VerificationMethod keyAgreement) {
  final jwk = Jwk.fromJson(keyAgreement.asJwk().toJson());
  return jwk.curve;
}
