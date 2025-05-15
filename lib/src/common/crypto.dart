import 'dart:typed_data';

import 'package:ssi/ssi.dart';
import 'package:elliptic/elliptic.dart' as ec;
import 'package:x25519/x25519.dart' as x25519;

({Uint8List privateKeyBytes, Uint8List? publicKeyBytes}) getEphemeralPrivateKey(
  KeyType keyType,
) {
  if (keyType == KeyType.p256) {
    return (
      privateKeyBytes: Uint8List.fromList(
        ec.getP256().generatePrivateKey().bytes,
      ),
      publicKeyBytes: null,
    );
  }

  if (keyType == KeyType.secp256k1) {
    return (
      privateKeyBytes: Uint8List.fromList(
        ec.getSecp256k1().generatePrivateKey().bytes,
      ),
      publicKeyBytes: null,
    );
  }

  if (keyType == KeyType.ed25519) {
    var eKeyPair = x25519.generateKeyPair();
    return (
      privateKeyBytes: Uint8List.fromList(eKeyPair.privateKey),
      publicKeyBytes: Uint8List.fromList(eKeyPair.publicKey),
    );
  }

  throw UnsupportedError('$keyType is not supported');
}
