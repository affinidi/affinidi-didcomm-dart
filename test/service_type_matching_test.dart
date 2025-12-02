import 'package:didcomm/src/common/did_document_service_type.dart';
import 'package:didcomm/src/extensions/did_document_extension.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

void main() {
  group('Service Type Matching (SSI v3.0+ compatibility)', () {
    test('should match StringServiceType correctly', () {
      final didDocument = DidDocument.fromJson({
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': 'did:example:123',
        'service': [
          {
            'id': 'service-1',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': 'https://example.com/didcomm',
          },
        ],
      });

      // Test getFirstServiceByType
      final service = didDocument
          .getFirstServiceByType(DidDocumentServiceType.didCommMessaging);
      expect(service, isNotNull);
      expect(service!.id, equals('service-1'));
    });

    test('should match SetServiceType correctly', () {
      final didDocument = DidDocument.fromJson({
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': 'did:example:123',
        'service': [
          {
            'id': 'service-1',
            'type': ['DIDCommMessaging', 'OtherService'],
            'serviceEndpoint': 'https://example.com/didcomm',
          },
        ],
      });

      // Test getFirstServiceByType with SetServiceType
      final service = didDocument
          .getFirstServiceByType(DidDocumentServiceType.didCommMessaging);
      expect(service, isNotNull);
      expect(service!.id, equals('service-1'));
    });

    test('should return null when service type does not match', () {
      final didDocument = DidDocument.fromJson({
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': 'did:example:123',
        'service': [
          {
            'id': 'service-1',
            'type': 'OtherService',
            'serviceEndpoint': 'https://example.com/other',
          },
        ],
      });

      // Test getFirstServiceByType returns null for non-matching type
      final service = didDocument
          .getFirstServiceByType(DidDocumentServiceType.didCommMessaging);
      expect(service, isNull);
    });

    test('should filter services by type correctly', () {
      final didDocument = DidDocument.fromJson({
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': 'did:example:123',
        'service': [
          {
            'id': 'service-1',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': 'https://example.com/didcomm1',
          },
          {
            'id': 'service-2',
            'type': ['DIDCommMessaging', 'Other'],
            'serviceEndpoint': 'https://example.com/didcomm2',
          },
          {
            'id': 'service-3',
            'type': 'Authentication',
            'serviceEndpoint': 'https://example.com/auth',
          },
        ],
      });

      // Test getServicesByType filters correctly
      final services = didDocument
          .getServicesByType(DidDocumentServiceType.didCommMessaging);
      expect(services.length, equals(2));
      expect(services[0].id, equals('service-1'));
      expect(services[1].id, equals('service-2'));
    });

    test('should throw ArgumentError when service type not found in toDio', () {
      final didDocument = DidDocument.fromJson({
        '@context': ['https://www.w3.org/ns/did/v1'],
        'id': 'did:example:123',
        'service': [
          {
            'id': 'service-1',
            'type': 'OtherService',
            'serviceEndpoint': 'https://example.com/other',
          },
        ],
      });

      // Test toDio throws when service type not found
      expect(
        () => didDocument.toDio(
            mediatorServiceType: DidDocumentServiceType.didCommMessaging),
        throwsArgumentError,
      );
    });
  });
}
