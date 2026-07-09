import 'package:ssi/ssi.dart';

import '../common/did.dart';

/// Extension methods for [DidManager] to simplify key pair retrieval by DID key ID.
extension DidManagerExtension on DidManager {
  /// Retrieves the [KeyPair] associated with the given [didKeyId] from this [DidManager].
  ///
  /// Throws if the key is not found or cannot be retrieved.
  Future<KeyPair> getKeyPairByDidKeyId(String didKeyId) async {
    final keyId = await getWalletKeyIdUniversally(didKeyId);

    if (keyId == null) {
      throw Exception('Key ID not found for DID key ID: $didKeyId');
    }

    return await getKeyPair(keyId);
  }

  /// Retrieves the wallet key associated with the given [didKeyId] universally.
  ///
  /// Tries to find the key by the fully qualified DID key ID first.
  /// If not found, falls back to the fragment after the hash sign, but only
  /// when the DID base of [didKeyId] matches this manager's own DID.
  /// This prevents a foreign DID URL (e.g. `did:example:mallory#key-2`) from
  /// resolving to a local wallet key via fragment-only matching.
  ///
  /// Returns a [String] containing the wallet key if found, or `null` if no key is associated
  /// with the provided [didKeyId].
  Future<String?> getWalletKeyIdUniversally(String didKeyId) async {
    var keyId = await getWalletKeyId(didKeyId);

    if (keyId == null) {
      final didBase = getDidFromId(didKeyId);
      final isFullyQualified = didBase.startsWith('did:');

      if (isFullyQualified) {
        final ownDid = (await getDidDocument()).id;
        if (didBase != ownDid) return null;
      }

      keyId = await getWalletKeyId(getKeyIdFromId(didKeyId));
    }

    return keyId;
  }
}
