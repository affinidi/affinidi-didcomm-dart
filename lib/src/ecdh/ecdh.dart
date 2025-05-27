import 'dart:typed_data';

import 'package:didcomm/src/ecdh/ecdh_es/ecdh_es_for_secp_and_p.dart';
import 'package:didcomm/src/ecdh/ecdh_es/ecdh_es_for_x.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:ssi/ssi.dart' show Wallet;

import '../../didcomm.dart';
import '../jwks/jwks.dart';
import '../messages/algorithm_types/algorithms_types.dart';
import '../messages/jwm/jwe_header.dart';
import '../messages/recipients/recipient.dart';
import 'ecdh_1pu/ecdh_1pu_for_secp256_and_p.dart';
import 'ecdh_1pu/ecdh_1pu_for_x.dart';

abstract class Ecdh {
  static Future<Uint8List> encrypt(
    Uint8List data, {
    required Wallet senderWallet,
    required String senderKeyId,
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
      senderWallet: senderWallet,
      senderKeyId: senderKeyId,
      data: data,
    );
  }

  static Future<Uint8List> decrypt(
    Uint8List data, {
    required Recipient self,
    required JweHeader jweHeader,
    required Jwk senderJwk,
    required Wallet recipientWallet,
    required Uint8List authenticationTag,
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
      throw UnsupportedCurveError(curveType);
      // ecdh = _createForXCurveForEncryption(
      //   jweHeader: jweHeader,
      //   recipientJwk: jwk,
      //   authenticationTag: authenticationTag,
      // );
    } else {
      throw UnsupportedCurveError(curveType);
    }

    return await ecdh.decryptData(
      data: self.encryptedKey,
      recipientWallet: recipientWallet,
      recipientKeyId: self.header.keyId.split('#').last,
    );
  }

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
    required Jwk senderJwk,
    required Uint8List authenticationTag,
  }) {
    final keyWrappingAlgorithm = jweHeader.keyWrappingAlgorithm;

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdhEs) {
      return EcdhEsForSecpAndP(
        jweHeader: jweHeader,
        publicKey:
            Jwk.fromJson(
              jweHeader.ephemeralKey.toJson(),
            ).toPublicKeyFromPoint(),
      );
    }

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      return Ecdh1PuForSecp256AndP(
        jweHeader: jweHeader,
        authenticationTag: authenticationTag,
        publicKey1:
            Jwk.fromJson(
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

  Future<Uint8List> encryptData({
    required Wallet senderWallet,
    required String senderKeyId,
    required Uint8List data,
  });

  Future<Uint8List> decryptData({
    required Wallet recipientWallet,
    required String recipientKeyId,
    required Uint8List data,
  });
}
