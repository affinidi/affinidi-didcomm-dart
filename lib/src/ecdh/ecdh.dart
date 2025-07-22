import 'dart:typed_data';

import 'package:ssi/ssi.dart' show DidManager, KeyPair;

import '../../didcomm.dart';
import '../jwks/jwk.dart';
import '../messages/jwm.dart';
import 'ecdh_1pu/ecdh_1pu_for_secp256_and_p.dart';
import 'ecdh_1pu/ecdh_1pu_for_x.dart';
import 'ecdh_es/ecdh_es_for_secp_and_p.dart';
import 'ecdh_es/ecdh_es_for_x.dart';

/// Abstract base class for ECDH key agreement operations in DIDComm.
///
/// Provides static methods for encryption and decryption using various ECDH algorithms and curves.
abstract class Ecdh {
  /// Encrypts [data] using the provided key material and JWE header.
  ///
  /// [data]: The plaintext data to encrypt.
  /// [senderKeyPair]: The sender's key pair.
  /// [recipientJwk]: The recipient's JWK.
  /// [ephemeralPrivateKeyBytes]: The ephemeral private key bytes.
  /// [jweHeader]: The JWE header.
  /// [authenticationTag]: The authentication tag for the JWE.
  ///
  /// Throws [UnsupportedCurveError] if the curve is not supported.
  static Future<Uint8List> encrypt(
    Uint8List data, {
    KeyPair? senderKeyPair,
    required Jwk recipientJwk,
    required Uint8List ephemeralPrivateKeyBytes,
    required JweHeader jweHeader,
    required Uint8List authenticationTag,
  }) async {
    final curveType = jweHeader.ephemeralKey.curve;
    final Ecdh ecdh;

    if (curveType.isSecp256OrPCurve()) {
      ecdh = _createForSecp256OrPCurveForEncryption(
        jweHeader: jweHeader,
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        recipientJwk: recipientJwk,
        authenticationTag: authenticationTag,
      );
    } else if (curveType.isXCurve()) {
      ecdh = _createForXCurveForEncryption(
        jweHeader: jweHeader,
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        recipientJwk: recipientJwk,
        authenticationTag: authenticationTag,
      );
    } else {
      throw UnsupportedCurveError(curveType);
    }

    return ecdh.encryptData(
      senderKeyPair: senderKeyPair,
      data: data,
    );
  }

  /// Decrypts [data] using the provided key material and JWE header.
  ///
  /// [data]: The encrypted data to decrypt.
  /// [self]: The recipient.
  /// [jweHeader]: The JWE header.
  /// [recipientDidManager]: The recipient's DID manager.
  /// [authenticationTag]: The authentication tag for the JWE.
  /// [senderJwk]: Optional sender's JWK.
  ///
  /// Throws [UnsupportedCurveError] if the curve is not supported.
  static Future<Uint8List> decrypt(
    Uint8List data, {
    required Recipient self,
    required JweHeader jweHeader,
    required DidManager recipientDidManager,
    required Uint8List authenticationTag,
    Jwk? senderJwk,
  }) async {
    final curveType = jweHeader.ephemeralKey.curve;
    final Ecdh ecdh;

    if (curveType.isSecp256OrPCurve()) {
      ecdh = _createForSecp256OrPCurveForDecryption(
        jweHeader: jweHeader,
        senderJwk: senderJwk,
        authenticationTag: authenticationTag,
      );
    } else if (curveType.isXCurve()) {
      ecdh = _createForXCurveForDecryption(
        jweHeader: jweHeader,
        senderJwk: senderJwk,
        authenticationTag: authenticationTag,
      );
    } else {
      throw UnsupportedCurveError(curveType);
    }

    final recipientKeyId = await recipientDidManager.getWalletKeyIdUniversally(
      self.header.keyId,
    );

    if (recipientKeyId == null) {
      throw Exception('JWK kid is not linked with any Key ID in the Wallet');
    }

    return await ecdh.decryptData(
      data: self.encryptedKey,
      recipientKeyPair: await recipientDidManager.getKeyPair(
        recipientKeyId,
      ),
    );
  }

  /// Encrypts [data] using the sender's key pair and ECDH shared secret.
  ///
  /// [senderKeyPair]: The sender's key pair.
  /// [data]: The plaintext data to encrypt.
  /// Returns the encrypted data as [Uint8List].
  Future<Uint8List> encryptData({
    KeyPair? senderKeyPair,
    required Uint8List data,
  });

  /// Decrypts [data] using the recipient's key pair and ECDH shared secret.
  ///
  /// [recipientKeyPair]: The recipient's key pair.
  /// [data]: The encrypted data to decrypt.
  /// Returns the decrypted data as [Uint8List].
  Future<Uint8List> decryptData({
    required KeyPair recipientKeyPair,
    required Uint8List data,
  });

  static Ecdh _createForSecp256OrPCurveForEncryption({
    required JweHeader jweHeader,
    Uint8List? ephemeralPrivateKeyBytes,
    required Jwk recipientJwk,
    required Uint8List authenticationTag,
  }) {
    final keyWrappingAlgorithm = jweHeader.keyWrappingAlgorithm;

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdhEs) {
      return EcdhEsForSecpAndP(
        jweHeader: jweHeader,
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        publicKey: recipientJwk.toPublicKeyFromPoint(),
      );
    }

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      final receiverPubKey = recipientJwk.toPublicKeyFromPoint();

      return Ecdh1PuForSecp256AndP(
        jweHeader: jweHeader,
        publicKey1: receiverPubKey,
        publicKey2: receiverPubKey,
        privateKey1: ephemeralPrivateKeyBytes?.toPrivateKey(
          curve: receiverPubKey.curve,
        ),
        authenticationTag: authenticationTag,
      );
    }

    throw UnsupportedKeyWrappingAlgorithmError(keyWrappingAlgorithm);
  }

  static Ecdh _createForSecp256OrPCurveForDecryption({
    required JweHeader jweHeader,
    required Uint8List authenticationTag,
    Jwk? senderJwk,
  }) {
    final keyWrappingAlgorithm = jweHeader.keyWrappingAlgorithm;

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdhEs) {
      return EcdhEsForSecpAndP(
        jweHeader: jweHeader,
        publicKey: Jwk.fromJson(
          jweHeader.ephemeralKey.toJson(),
        ).toPublicKeyFromPoint(),
      );
    }

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      if (senderJwk == null) {
        throw ArgumentError('senderJwk is required for ecdh1Pu', 'senderJwk');
      }

      return Ecdh1PuForSecp256AndP(
        jweHeader: jweHeader,
        authenticationTag: authenticationTag,
        publicKey1: Jwk.fromJson(
          jweHeader.ephemeralKey.toJson(),
        ).toPublicKeyFromPoint(),
        publicKey2: senderJwk.toPublicKeyFromPoint(),
      );
    }

    throw UnsupportedKeyWrappingAlgorithmError(keyWrappingAlgorithm);
  }

  static Ecdh _createForXCurveForEncryption({
    required JweHeader jweHeader,
    Uint8List? ephemeralPrivateKeyBytes,
    required Jwk recipientJwk,
    required Uint8List authenticationTag,
  }) {
    final keyWrappingAlgorithm = jweHeader.keyWrappingAlgorithm;

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdhEs) {
      return EcdhEsForX(
        jweHeader: jweHeader,
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        publicKeyBytes: recipientJwk.x!,
      );
    }

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      return Ecdh1PuForX(
        jweHeader: jweHeader,
        publicKeyBytes1: recipientJwk.x!,
        publicKeyBytes2: recipientJwk.x!,
        privateKeyBytes1: ephemeralPrivateKeyBytes,
        authenticationTag: authenticationTag,
      );
    }

    throw UnsupportedKeyWrappingAlgorithmError(keyWrappingAlgorithm);
  }

  static Ecdh _createForXCurveForDecryption({
    required JweHeader jweHeader,
    required Uint8List authenticationTag,
    Jwk? senderJwk,
  }) {
    final keyWrappingAlgorithm = jweHeader.keyWrappingAlgorithm;

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdhEs) {
      return EcdhEsForX(
        jweHeader: jweHeader,
        publicKeyBytes: jweHeader.ephemeralKey.x,
      );
    }

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      if (senderJwk == null) {
        throw ArgumentError('senderJwk is required for ecdh1Pu', 'senderJwk');
      }

      return Ecdh1PuForX(
        jweHeader: jweHeader,
        publicKeyBytes1: jweHeader.ephemeralKey.x,
        publicKeyBytes2: senderJwk.x!,
        authenticationTag: authenticationTag,
      );
    }

    throw UnsupportedKeyWrappingAlgorithmError(keyWrappingAlgorithm);
  }
}
