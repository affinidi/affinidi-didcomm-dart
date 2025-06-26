import 'dart:typed_data';

import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:elliptic/elliptic.dart' as ec;
import 'package:ssi/ssi.dart' show KeyType;
import 'package:x25519/x25519.dart' as x25519;

import '../errors/errors.dart';
import '../messages/algorithm_types/algorithms_types.dart';

({Uint8List privateKeyBytes, Uint8List? publicKeyBytes})
    generateEphemeralKeyPair(KeyType keyType) {
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

  throw UnsupportedKeyTypeError(keyType);
}

ec.PrivateKey getPrivateKeyFromBytes(
  Uint8List bytes, {
  required KeyType keyType,
}) {
  if (keyType == KeyType.p256) {
    return ec.PrivateKey.fromBytes(ec.getP256(), bytes);
  }

  if (keyType == KeyType.secp256k1) {
    return ec.PrivateKey.fromBytes(ec.getSecp256k1(), bytes);
  }

  throw UnsupportedKeyTypeError(keyType);
}

ck.Encrypter createSymmetricEncrypter(
  EncryptionAlgorithm encryptionAlgorithm,
  ck.SymmetricKey encryptionKey,
) {
  if (encryptionAlgorithm == EncryptionAlgorithm.a256cbc) {
    return encryptionKey.createEncrypter(
      ck.algorithms.encryption.aes.cbcWithHmac.sha512,
    );
  }

  if (encryptionAlgorithm == EncryptionAlgorithm.a256gcm) {
    return encryptionKey.createEncrypter(ck.algorithms.encryption.aes.gcm);
  }

  throw UnsupportedEncryptionAlgorithmError(encryptionAlgorithm);
}
