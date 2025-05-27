import 'dart:typed_data';
import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

import '../../extensions/extensions.dart';
import 'ecdh_es.dart';

class EcdhEsForX extends EcdhEs {
  final Uint8List publicKeyBytes;
  final Uint8List? ephemeralPrivateKeyBytes;

  EcdhEsForX({
    required this.publicKeyBytes,
    this.ephemeralPrivateKeyBytes,
    required super.jweHeader,
  });

  @override
  Future<Uint8List> getEncryptionSecret() async {
    if (ephemeralPrivateKeyBytes == null) {
      throw Exception('Private key is needed for encryption data.');
    }

    return x25519.X25519(ephemeralPrivateKeyBytes!, publicKeyBytes);
  }

  @override
  Future<Uint8List> getDecryptionSecret({
    required Wallet recipientWallet,
    required String recipientKeyId,
  }) async {
    return await recipientWallet.computeEcdhSecret(
      keyId: recipientKeyId,
      othersPublicKeyBytes: publicKeyBytes,
    );
  }
}
