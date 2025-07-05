import 'package:ssi/ssi.dart';

import '../common/did.dart';

/// Extension methods for [DidController] to simplify key pair retrieval by DID key ID.
extension DidControllerExtension on DidController {
  /// Retrieves the [KeyPair] associated with the given [didKeyId] from this [DidController].
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
  /// If not found, tries to find by the fragment after the hash sign.
  ///
  /// Returns a [String] containing the wallet key if found, or `null` if no key is associated
  /// with the provided [didKeyId].
  Future<String?> getWalletKeyIdUniversally(String didKeyId) async {
    var keyId = await getWalletKeyId(didKeyId);
    keyId ??= await getWalletKeyId(getKeyIdFromId(didKeyId));

    return keyId;
  }
}
