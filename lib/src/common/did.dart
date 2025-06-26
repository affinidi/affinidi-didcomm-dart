/// Extracts the DID from a DID ID.
///
/// [id]: The DID ID (e.g., 'did:example:123#key-1').
/// Returns the base DID string (e.g., 'did:example:123').
String getDidFromId(String id) {
  return id.split('#').first;
}
