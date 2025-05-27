import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:ssi/ssi.dart';

import '../../common/encoding.dart';
import '../../messages/algorithm_types/key_wrapping_algorithm.dart';
import '../../messages/jwm/jwe_header.dart';
import '../ecdh.dart';

abstract class EcdhEs implements Ecdh {
  final JweHeader jweHeader;

  EcdhEs({required this.jweHeader});

  Future<Uint8List> getEncryptionSecret();
  Future<Uint8List> getDecryptionSecret({
    required Wallet recipientWallet,
    required String recipientKeyId,
  });

  @override
  Future<Uint8List> encryptData({
    required Wallet senderWallet,
    required String senderKeyId,
    required Uint8List data,
  }) async {
    final secret = await getEncryptionSecret();
    final sharedSecret = _generateSharedSecret(secret);

    final kw = _getKeyWrappingEncrypter(sharedSecret);
    return kw.encrypt(data).data;
  }

  @override
  Future<Uint8List> decryptData({
    required Wallet recipientWallet,
    required String recipientKeyId,
    required Uint8List data,
  }) async {
    final secret = await getDecryptionSecret(
      recipientWallet: recipientWallet,
      recipientKeyId: recipientKeyId,
    );
    final sharedSecret = _generateSharedSecret(secret);

    final kw = _getKeyWrappingEncrypter(sharedSecret);
    return kw.decrypt(ck.EncryptionResult(data));
  }

  _generateSharedSecret(Uint8List z) {
    //Didcomm only uses A256KW
    final keyDataLen = 256;
    final suppPubInfo = _int32BigEndianBytes(keyDataLen);

    final encAscii = ascii.encode(KeyWrappingAlgorithm.ecdhEs.value);
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
