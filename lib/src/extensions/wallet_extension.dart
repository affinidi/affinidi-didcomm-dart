import 'dart:typed_data';

import 'package:ssi/ssi.dart';

extension WalletExtension on Wallet {
  Future<Uint8List> computeEcdhSecret({
    required String keyId,
    required Uint8List othersPublicKeyBytes,
  }) async {
    final keyPair = (await getKeyPair(keyId)) as P256KeyPair;

    return await keyPair.computeEcdhSecret(
      Uint8List.fromList(othersPublicKeyBytes),
    );
  }
}
