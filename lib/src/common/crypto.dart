import 'dart:typed_data';

import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:elliptic/elliptic.dart' as ec;
import 'package:ssi/ssi.dart' show KeyType;
import 'package:x25519/x25519.dart' as x25519;

import '../errors/errors.dart';
import '../messages/algorithm_types/algorithms_types.dart';

final _keyTypeToEcCurveMap = {
  KeyType.p256: ec.getP256(),
  KeyType.p384: ec.getP384(),
  KeyType.p521: ec.getP521(),
  KeyType.secp256k1: ec.getSecp256k1(),
};

/// Generates an ephemeral key pair for the given [keyType].
///
/// [keyType]: The type of key to generate (e.g., p256, secp256k1, ed25519).
/// Returns a record containing the private key bytes and, for ed25519, the public key bytes.
/// Throws [UnsupportedKeyTypeError] if the key type is not supported.
({Uint8List privateKeyBytes, Uint8List? publicKeyBytes})
    generateEphemeralKeyPair(KeyType keyType) {
  if (keyType == KeyType.ed25519) {
    final keyPair = x25519.generateKeyPair();

    return (
      privateKeyBytes: Uint8List.fromList(keyPair.privateKey),
      publicKeyBytes: Uint8List.fromList(keyPair.publicKey),
    );
  }

  if (_keyTypeToEcCurveMap.containsKey(keyType)) {
    final ecCurve = _keyTypeToEcCurveMap[keyType]!;

    return (
      privateKeyBytes: Uint8List.fromList(
        ecCurve.generatePrivateKey().bytes,
      ),
      publicKeyBytes: null,
    );
  }

  throw UnsupportedKeyTypeError(keyType);
}

/// Returns an [ec.PrivateKey] from the given [bytes] for the specified [keyType].
///
/// [bytes]: The private key bytes.
/// [keyType]: The type of key (must be p256 or secp256k1).
/// Throws [UnsupportedKeyTypeError] if the key type is not supported.
ec.PrivateKey getPrivateKeyFromBytes(
  Uint8List bytes, {
  required KeyType keyType,
}) {
  if (_keyTypeToEcCurveMap.containsKey(keyType)) {
    return ec.PrivateKey.fromBytes(_keyTypeToEcCurveMap[keyType]!, bytes);
  }

  throw UnsupportedKeyTypeError(keyType);
}

/// Creates a symmetric [ck.Encrypter] for the given [encryptionAlgorithm] and [encryptionKey].
///
/// [encryptionAlgorithm]: The encryption algorithm to use (A256CBC-HS512 or A256GCM).
/// [encryptionKey]: The symmetric key to use for encryption.
/// Throws [UnsupportedEncryptionAlgorithmError] if the algorithm is not supported.
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
