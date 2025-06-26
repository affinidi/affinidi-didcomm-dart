/// Enum representing supported service types in a DID Document.
///
/// - [didCommMessaging]: Service endpoint for DIDComm Messaging.
/// - [authentication]: Service endpoint for authentication purposes.
// TODO: prevent failure for unlisted service types
enum DidDocumentServiceType {
  /// Service endpoint for DIDComm Messaging ("DIDCommMessaging").
  didCommMessaging('DIDCommMessaging'),

  /// Service endpoint for authentication ("Authentication").
  authentication('Authentication');

  /// The string value as used in the DID Document service type.
  final String value;

  /// Constructs a [DidDocumentServiceType] with the given string [value].
  const DidDocumentServiceType(this.value);
}
