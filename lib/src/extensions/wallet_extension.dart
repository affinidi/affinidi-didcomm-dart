import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import '../../didcomm.dart';

extension WalletExtension on Wallet {
  Future<Uint8List> computeEcdhSecret({
    required String keyId,
    required Uint8List othersPublicKeyBytes,
  }) async {
    final keyPair = await getKeyPair(keyId);

    if (keyPair is P256KeyPair) {
      return await keyPair.computeEcdhSecret(othersPublicKeyBytes);
    }

    if (keyPair is Ed25519KeyPair) {
      return await keyPair.computeEcdhSecret(othersPublicKeyBytes);
    }

    throw UnsupportedKeyTypeError(keyPair.publicKey.type);
  }
}
