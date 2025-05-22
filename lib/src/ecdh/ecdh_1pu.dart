import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:elliptic/elliptic.dart' as ec;
import 'package:elliptic/ecdh.dart' as ecdh;
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

import '../common/encoding.dart';
import '../extensions/extensions.dart';
import '../messages/algorithm_types/algorithms_types.dart';
import '../messages/jwm/jwe_header.dart';
import 'ecdh_profile.dart';

abstract class ECDH1PU implements ECDHProfile {
  final List<int> authenticationTag;
  final KeyWrappingAlgorithm keyWrappingAlgorithm;
  final JweHeader jweHeader;

  ECDH1PU({
    required this.authenticationTag,
    required this.keyWrappingAlgorithm,
    required this.jweHeader,
  });

  Future<({Uint8List ze, Uint8List zs})> getEncryptionSecrets({
    required Wallet wallet,
    required String keyId,
  });

  Future<({Uint8List ze, Uint8List zs})> getDecryptionSecrets({
    required Wallet wallet,
    required String keyId,
  });

  @override
  Future<Uint8List> encryptData({
    required Wallet wallet,
    required String keyId,
    required Uint8List data,
  }) async {
    final secrets = await getEncryptionSecrets(wallet: wallet, keyId: keyId);
    final sharedSecret = _generateSharedSecret(secrets.ze, secrets.zs);

    final kw = _getKeyWrappingEncrypter(sharedSecret);
    return kw.encrypt(data).data;
  }

  @override
  Future<Uint8List> decryptData({
    required Wallet wallet,
    required String keyId,
    required Uint8List data,
  }) async {
    final secrets = await getDecryptionSecrets(wallet: wallet, keyId: keyId);
    final sharedSecret = _generateSharedSecret(secrets.ze, secrets.zs);

    final kw = _getKeyWrappingEncrypter(sharedSecret);
    return kw.decrypt(ck.EncryptionResult(data));
  }

  List<int> _generateSharedSecret(List<int> ze, List<int> zs) {
    if (jweHeader.agreementPartyUInfo == null) {
      throw ArgumentError(
        'Agreement Party U Info is required',
        'agreementPartyUInfo',
      );
    }

    if (jweHeader.agreementPartyVInfo == null) {
      throw ArgumentError(
        'Agreement Party V Info is required',
        'agreementPartyVInfo',
      );
    }

    var z = ze + zs;

    // Didcomm only uses A256KW
    final keyDataLen = 256;
    final cctagLen = _int32BigEndianBytes(authenticationTag.length);
    final suppPubInfo =
        _int32BigEndianBytes(keyDataLen) + cctagLen + authenticationTag;

    final encAscii = ascii.encode(keyWrappingAlgorithm.value);
    final encLength = _int32BigEndianBytes(encAscii.length);

    final partyU = base64UrlDecodeWithPadding(jweHeader.agreementPartyUInfo!);
    final partyULength = _int32BigEndianBytes(partyU.length);

    final partyV = base64UrlDecodeWithPadding(jweHeader.agreementPartyVInfo!);
    final partyVLength = _int32BigEndianBytes(partyV.length);

    final otherInfo =
        encLength +
        encAscii +
        partyULength +
        partyU +
        partyVLength +
        partyV +
        suppPubInfo;

    final kdfIn = [0, 0, 0, 1] + z + otherInfo;
    return sha256.convert(kdfIn).bytes;
  }

  ck.Encrypter _getKeyWrappingEncrypter(List<int> sharedSecret) {
    final sharedSecretJwk = {'kty': 'oct', 'k': base64UrlEncode(sharedSecret)};
    final keyPair = ck.KeyPair.fromJwk(sharedSecretJwk);

    if (keyPair == null) {
      throw Exception('Failed to construct a key pair for a shared secret');
    }

    return keyPair.publicKey!.createEncrypter(
      ck.algorithms.encryption.aes.keyWrap,
    );
  }

  Uint8List _int32BigEndianBytes(int value) =>
      Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);
}

class ECDH1PU_Elliptic extends ECDH1PU implements ECDHProfile {
  final ec.PublicKey publicKey1;
  final ec.PublicKey publicKey2;
  final ec.PrivateKey? privateKey1;

  ECDH1PU_Elliptic({
    required super.authenticationTag,
    required super.keyWrappingAlgorithm,
    required super.jweHeader,
    // public key 1
    required this.publicKey1,
    // public key 2
    required this.publicKey2,
    this.privateKey1,
  });

  @override
  Future<({Uint8List ze, Uint8List zs})> getEncryptionSecrets({
    required Wallet wallet,
    required String keyId,
  }) async {
    if (privateKey1 == null) {
      throw Exception('ephemeralPrivateKey is required for encryption data');
    }

    final ze = ecdh.computeSecret(privateKey1!, publicKey1);
    final zs = await wallet.computeEcdhSecret(
      keyId: keyId,
      othersPublicKeyBytes: publicKey2.toBytes(),
    );

    return (ze: Uint8List.fromList(ze), zs: Uint8List.fromList(zs));
  }

  @override
  Future<({Uint8List ze, Uint8List zs})> getDecryptionSecrets({
    required Wallet wallet,
    required String keyId,
  }) async {
    final ze = await wallet.computeEcdhSecret(
      keyId: keyId,
      othersPublicKeyBytes: publicKey1.toBytes(),
    );

    final zs = await wallet.computeEcdhSecret(
      keyId: keyId,
      othersPublicKeyBytes: publicKey2.toBytes(),
    );

    return (ze: Uint8List.fromList(ze), zs: Uint8List.fromList(zs));
  }
}

class ECDH1PU_X25519 extends ECDH1PU {
  final Uint8List publicKeyBytes1;
  final Uint8List publicKeyBytes2;
  final Uint8List? privateKeyBytes1;

  ECDH1PU_X25519({
    required super.authenticationTag,
    required super.keyWrappingAlgorithm,
    required super.jweHeader,
    required this.publicKeyBytes1,
    required this.publicKeyBytes2,
    this.privateKeyBytes1,
  });

  @override
  Future<({Uint8List ze, Uint8List zs})> getEncryptionSecrets({
    required Wallet wallet,
    required String keyId,
  }) async {
    if (privateKeyBytes1 == null) {
      throw Exception('Private key needed for encryption data.');
    }

    final ze = x25519.X25519(privateKeyBytes1!.sublist(0, 32), publicKeyBytes1);

    final zs = await wallet.computeEcdhSecret(
      keyId: keyId,
      othersPublicKeyBytes: publicKeyBytes2,
    );

    return (ze: ze, zs: zs);
  }

  @override
  Future<({Uint8List ze, Uint8List zs})> getDecryptionSecrets({
    required Wallet wallet,
    required String keyId,
  }) async {
    final ze = await wallet.computeEcdhSecret(
      keyId: keyId,
      othersPublicKeyBytes: publicKeyBytes1,
    );

    final zs = await wallet.computeEcdhSecret(
      keyId: keyId,
      othersPublicKeyBytes: publicKeyBytes2,
    );

    return (ze: ze, zs: zs);
  }
}
