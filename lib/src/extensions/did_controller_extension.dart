import 'package:ssi/ssi.dart';

/// Extension methods for [DidController] to simplify key pair retrieval by DID key ID.
extension DidControllerExtension on DidController {
  /// Retrieves the [KeyPair] associated with the given [didKeyId] from this [DidController].
  ///
  /// Throws if the key is not found or cannot be retrieved.
  Future<KeyPair> getKeyPairByDidKeyId(String didKeyId) async {
    final key = await getKey(didKeyId);
    return key.keyPair;
  }
}
