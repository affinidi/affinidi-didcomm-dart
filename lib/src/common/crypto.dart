import 'dart:typed_data';

import 'package:ssi/ssi.dart' show KeyType;
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:elliptic/elliptic.dart' as ec;
import 'package:x25519/x25519.dart' as x25519;

// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as pointycastle_utils;

import '../common/encoding.dart';
import '../errors/errors.dart';
import '../messages/algorithm_types/encryption_algorithm.dart';

({Uint8List privateKeyBytes, Uint8List? publicKeyBytes}) getEphemeralKeyPair(
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

({String x, String y}) getPublicKeyPoint(ec.PublicKey publicKey) {
  final xBytes = _bigIntToUint8List(publicKey.X, length: 32);
  final yBytes = _bigIntToUint8List(publicKey.Y, length: 32);

  return (
    x: base64UrlEncodeNoPadding(xBytes),
    y: base64UrlEncodeNoPadding(yBytes),
  );
}

ck.Encrypter createEncrypter(
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

Uint8List _bigIntToUint8List(BigInt value, {int? length}) {
  var bytes =
      value < BigInt.zero
          ? pointycastle_utils.encodeBigInt(value)
          : pointycastle_utils.encodeBigIntAsUnsigned(value);

  if (length != null) {
    if (bytes.length > length) {
      throw ArgumentError(
        'The length of the byte array is greater than the specified length.',
      );
    }

    if (bytes.length < length) {
      final padded = Uint8List(length);

      padded.setRange(length - bytes.length, length, bytes);
      bytes = padded;
    }
  }

  return bytes;
}
