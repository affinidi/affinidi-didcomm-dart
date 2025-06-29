import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:ssi/ssi.dart';

import '../../common/encoding.dart';
import '../../messages/algorithm_types/key_wrapping_algorithm.dart';
import '../../messages/jwm.dart';
import '../ecdh.dart';

/// Abstract base class for ECDH-ES key agreement in DIDComm.
///
/// Provides methods for computing encryption and decryption secrets and for encrypting/decrypting data.
abstract class EcdhEs implements Ecdh {
  /// The JWE header.
  final JweHeader jweHeader;

  /// Constructs an [EcdhEs] instance.
  ///
  /// [jweHeader]: The JWE header.
  EcdhEs({required this.jweHeader});

  /// Computes the encryption secret for ECDH-ES.
  ///
  /// Returns the shared secret as [Uint8List] for use in key wrapping.
  Future<Uint8List> getEncryptionSecret();

  /// Computes the decryption secret for ECDH-ES.
  ///
  /// [recipientKeyPair]: The recipient's key pair used for ECDH key agreement.
  /// Returns the shared secret as [Uint8List] for use in key unwrapping.
  Future<Uint8List> getDecryptionSecret({
    required KeyPair recipientKeyPair,
  });

  /// Encrypts [data] using the ECDH-ES shared secret.
  ///
  /// [senderKeyPair]: The sender's key pair (not used in ECDH-ES, but required by the interface).
  /// [data]: The plaintext data to encrypt.
  /// Returns the encrypted data as [Uint8List].
  @override
  Future<Uint8List> encryptData({
    KeyPair? senderKeyPair,
    required Uint8List data,
  }) async {
    final secret = await getEncryptionSecret();
    final sharedSecret = _generateSharedSecret(secret);

    final kw = _getKeyWrappingEncrypter(sharedSecret);
    return kw.encrypt(data).data;
  }

  /// Decrypts [data] using the recipient's key pair and ECDH-ES shared secret.
  ///
  /// [recipientKeyPair]: The recipient's key pair used for ECDH key agreement.
  /// [data]: The encrypted data to decrypt.
  /// Returns the decrypted data as [Uint8List].
  @override
  Future<Uint8List> decryptData({
    required KeyPair recipientKeyPair,
    required Uint8List data,
  }) async {
    final secret = await getDecryptionSecret(
      recipientKeyPair: recipientKeyPair,
    );

    final sharedSecret = _generateSharedSecret(secret);
    final kw = _getKeyWrappingEncrypter(sharedSecret);

    return kw.decrypt(ck.EncryptionResult(data));
  }

  List<int> _generateSharedSecret(Uint8List z) {
    //Didcomm only uses A256KW
    final keyDataLen = 256;
    final suppPubInfo = _int32BigEndianBytes(keyDataLen);

    final encAscii = ascii.encode(KeyWrappingAlgorithm.ecdhEs.value);
    final encLength = _int32BigEndianBytes(encAscii.length);

    final partyU = jweHeader.agreementPartyUInfo != null
        ? base64UrlDecodeWithPadding(jweHeader.agreementPartyUInfo!)
        : Uint8List(0);

    final partyULength = _int32BigEndianBytes(partyU.length);

    final partyV = jweHeader.agreementPartyVInfo != null
        ? base64UrlDecodeWithPadding(jweHeader.agreementPartyVInfo!)
        : Uint8List(0);

    final partyVLength = _int32BigEndianBytes(partyV.length);

    final otherInfo = encLength +
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
      throw ArgumentError('Failed to construct a key pair for a shared secret');
    }

    return keyPair.publicKey!.createEncrypter(
      ck.algorithms.encryption.aes.keyWrap,
    );
  }

  Uint8List _int32BigEndianBytes(int value) =>
      Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);
}
