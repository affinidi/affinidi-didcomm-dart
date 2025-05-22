import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:elliptic/elliptic.dart' as ec;
import 'package:elliptic/ecdh.dart' as ecdh;
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

import '../common/encoding.dart';
import '../messages/jwm/jwe_header.dart';
import 'ecdh_profile.dart';

abstract class ECDHES implements ECDHProfile {
  final JweHeader jweHeader;

  ECDHES({required this.jweHeader});

  Future<Uint8List> getEncryptionSecret();
  Future<Uint8List> getDecryptionSecret({
    required Wallet wallet,
    required String keyId,
  });

  @override
  Future<Uint8List> encryptData({
    required Wallet wallet,
    required String keyId,
    required Uint8List data,
  }) async {
    final secret = await getEncryptionSecret();
    final sharedSecret = _generateSharedSecret(secret);

    final kw = _getKeyWrapEncrypter(sharedSecret);
    return kw.encrypt(data).data;
  }

  @override
  Future<Uint8List> decryptData({
    required Wallet wallet,
    required String keyId,
    required Uint8List data,
  }) async {
    final secret = await getDecryptionSecret(wallet: wallet, keyId: keyId);
    final sharedSecret = _generateSharedSecret(secret);

    final kw = _getKeyWrapEncrypter(sharedSecret);
    return kw.decrypt(ck.EncryptionResult(data));
  }

  _generateSharedSecret(Uint8List z) {
    //Didcomm only uses A256KW
    final keyDataLen = 256;
    final suppPubInfo = _int32BigEndianBytes(keyDataLen);

    final encAscii = ascii.encode('ECDH-ES+A256KW');
    final encLength = _int32BigEndianBytes(encAscii.length);

    final partyU =
        jweHeader.agreementPartyUInfo != null
            ? base64UrlDecodeWithPadding(jweHeader.agreementPartyUInfo!)
            : Uint8List(0);

    final partyULength = _int32BigEndianBytes(partyU.length);

    final partyV =
        jweHeader.agreementPartyVInfo != null
            ? base64UrlDecodeWithPadding(jweHeader.agreementPartyVInfo!)
            : Uint8List(0);

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
    final digest = sha256.convert(kdfIn);

    return digest.bytes;
  }

  ck.Encrypter _getKeyWrapEncrypter(List<int> sharedSecret) {
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

class ECDHES_Elliptic extends ECDHES implements ECDHProfile {
  final ec.PublicKey publicKey;
  final Uint8List? ephemeralPrivateKeyBytes;

  ECDHES_Elliptic({
    required this.publicKey,
    this.ephemeralPrivateKeyBytes,
    required super.jweHeader,
  });

  @override
  Future<Uint8List> getEncryptionSecret() async {
    if (ephemeralPrivateKeyBytes == null) {
      throw Exception('Private key needed for encryption data.');
    }

    final privateKey = ec.PrivateKey.fromBytes(
      publicKey.curve,
      ephemeralPrivateKeyBytes!,
    );

    return Uint8List.fromList(ecdh.computeSecret(privateKey, publicKey));
  }

  @override
  Future<Uint8List> getDecryptionSecret({
    required Wallet wallet,
    required String keyId,
  }) async {
    return await wallet.computeEcdhSecret(
      keyId: keyId,
      othersPublicKeyBytes: publicKey.toBytes(),
    );
  }
}

class ECDHES_X25519 extends ECDHES implements ECDHProfile {
  final Uint8List publicKey;
  final Uint8List? ephemeralPrivateKeyBytes;

  ECDHES_X25519({
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
