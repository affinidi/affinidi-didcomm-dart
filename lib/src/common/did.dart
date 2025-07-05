/// Extracts the DID from a DID ID.
///
/// [id]: The DID ID (e.g., 'did:example:123#key-1').
/// Returns the base DID string (e.g., 'did:example:123').
String getDidFromId(String id) {
  return id.split('#').first;
}

/// Extracts the key identifier from a given DID (Decentralized Identifier) string.
///
/// The [id] parameter is expected to be a DID URL or identifier containing a key reference.
///
/// Returns the key identifier as a [String].
String getKeyIdFromId(String id) {
  return '#${id.split('#').last}';
}
