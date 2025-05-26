import 'dart:typed_data';
import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

import '../../extensions/extensions.dart';
import 'ecdh_es.dart';

class EcdhEsForX extends EcdhEs {
  final Uint8List publicKey;
  final Uint8List? ephemeralPrivateKeyBytes;

  EcdhEsForX({
    required this.publicKey,
    this.ephemeralPrivateKeyBytes,
    required super.jweHeader,
  });

  @override
  Future<Uint8List> getEncryptionSecret() async {
    if (ephemeralPrivateKeyBytes == null) {
      throw Exception('Private key needed for encryption data.');
    }

    return x25519.X25519(ephemeralPrivateKeyBytes!, publicKey);
  }

  @override
  Future<Uint8List> getDecryptionSecret({
    required Wallet wallet,
    required String keyId,
  }) async {
    return await wallet.computeEcdhSecret(
      keyId: keyId,
      othersPublicKeyBytes: publicKey,
    );
  }
}
