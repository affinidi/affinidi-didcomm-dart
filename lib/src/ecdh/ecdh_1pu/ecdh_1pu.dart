import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:ssi/ssi.dart';

import '../../common/encoding.dart';
import '../../messages/algorithm_types/algorithms_types.dart';
import '../../messages/jwm.dart';
import '../ecdh.dart';

/// Abstract base class for ECDH-1PU key agreement in DIDComm.
///
/// Provides methods for computing encryption and decryption secrets and for encrypting/decrypting data.
abstract class Ecdh1Pu implements Ecdh {
  /// The authentication tag for the JWE.
  final List<int> authenticationTag;

  /// The JWE header.
  final JweHeader jweHeader;

  /// Constructs an [Ecdh1Pu] instance.
  ///
  /// [authenticationTag]: The authentication tag for the JWE.
  /// [jweHeader]: The JWE header.
  Ecdh1Pu({required this.authenticationTag, required this.jweHeader});

  /// Computes the encryption secrets (ze, zs) for ECDH-1PU.
  ///
  /// [senderKeyPair]: The sender's key pair used for ECDH-1PU key agreement.
  /// Returns a record containing ze and zs as [Uint8List].
  Future<({Uint8List ze, Uint8List zs})> getEncryptionSecrets({
    required KeyPair senderKeyPair,
  });

  /// Computes the decryption secrets (ze, zs) for ECDH-1PU.
  ///
  /// [recipientKeyPair]: The recipient's key pair used for ECDH-1PU key agreement.
  /// Returns a record containing ze and zs as [Uint8List].
  Future<({Uint8List ze, Uint8List zs})> getDecryptionSecrets({
    required KeyPair recipientKeyPair,
  });

  /// Encrypts [data] using the sender's key pair and ECDH-1PU shared secrets.
  ///
  /// [senderKeyPair]: The sender's key pair (required for ECDH-1PU key agreement).
  /// [data]: The plaintext data to encrypt.
  /// Returns the encrypted data as [Uint8List].
  @override
  Future<Uint8List> encryptData({
    KeyPair? senderKeyPair,
    required Uint8List data,
  }) async {
    if (senderKeyPair == null) {
      throw ArgumentError(
        'Sender key pair is required for ${KeyWrappingAlgorithm.ecdh1Pu.value} encryption',
        'senderKeyPair',
      );
    }

    final secrets = await getEncryptionSecrets(
      senderKeyPair: senderKeyPair,
    );

    final sharedSecret = _generateSharedSecret(secrets.ze, secrets.zs);
    final kw = _getKeyWrappingEncrypter(sharedSecret);

    return kw.encrypt(data).data;
  }

  /// Decrypts [data] using the recipient's key pair and ECDH-1PU shared secrets.
  ///
  /// [recipientKeyPair]: The recipient's key pair used for ECDH-1PU key agreement.
  /// [data]: The encrypted data to decrypt.
  /// Returns the decrypted data as [Uint8List].
  @override
  Future<Uint8List> decryptData({
    required KeyPair recipientKeyPair,
    required Uint8List data,
  }) async {
    final secrets = await getDecryptionSecrets(
      recipientKeyPair: recipientKeyPair,
    );

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

    final encAscii = ascii.encode(KeyWrappingAlgorithm.ecdh1Pu.value);
    final encLength = _int32BigEndianBytes(encAscii.length);

    final partyU = base64UrlDecodeWithPadding(jweHeader.agreementPartyUInfo!);
    final partyULength = _int32BigEndianBytes(partyU.length);

    final partyV = base64UrlDecodeWithPadding(jweHeader.agreementPartyVInfo!);
    final partyVLength = _int32BigEndianBytes(partyV.length);

    final otherInfo = encLength +
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
