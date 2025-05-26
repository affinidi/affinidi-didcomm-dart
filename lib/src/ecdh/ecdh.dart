import 'dart:typed_data';

import 'package:didcomm/src/ecdh/ecdh_es/ecdh_es_for_secp_and_p.dart';
import 'package:didcomm/src/ecdh/ecdh_es/ecdh_es_for_x.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:ssi/ssi.dart' show Wallet;

import '../../didcomm.dart';
import '../jwks/jwks.dart';
import '../messages/algorithm_types/algorithms_types.dart';
import '../messages/jwm/jwe_header.dart';
import 'ecdh_1pu/ecdh_1pu_for_secp256_and_p.dart';
import 'ecdh_1pu/ecdh_1pu_for_x.dart';

abstract class Ecdh {
  static Future<Uint8List> encrypt(
    Uint8List data, {
    required Wallet wallet,
    required String keyId,
    required Jwk jwk,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required Uint8List ephemeralPrivateKeyBytes,
    required JweHeader jweHeader,
    required Uint8List authenticationTag,
  }) async {
    final curveType = jweHeader.ephemeralKey.curve;
    final Ecdh ecdh;

    if (curveType.isSecp256OrPCurve()) {
      ecdh = _createForSecp256OrPCurve(
        keyWrappingAlgorithm: keyWrappingAlgorithm,
        jweHeader: jweHeader,
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        jwk: jwk,
        authenticationTag: authenticationTag,
      );
    } else if (curveType.isXCurve()) {
      ecdh = _createForXCurve(
        keyWrappingAlgorithm: keyWrappingAlgorithm,
        jweHeader: jweHeader,
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        jwk: jwk,
        authenticationTag: authenticationTag,
      );
    } else {
      throw UnsupportedCurveError(curveType);
    }

    return ecdh.encryptData(wallet: wallet, keyId: keyId, data: data);
  }

  static Ecdh _createForSecp256OrPCurve({
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required JweHeader jweHeader,
    required Uint8List ephemeralPrivateKeyBytes,
    required Jwk jwk,
    required Uint8List authenticationTag,
  }) {
    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdhEs) {
      return EcdhEsForX(
        jweHeader: jweHeader,
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        publicKey: jwk.x!,
      );
    }

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      final receiverPubKey = jwk.toPublicKeyFromPoint();

      return Ecdh1PuForSecp256AndP(
        jweHeader: jweHeader,
        publicKey1: receiverPubKey,
        publicKey2: receiverPubKey,
        privateKey1: ephemeralPrivateKeyBytes.toPrivateKey(
          curve: receiverPubKey.curve,
        ),
        authenticationTag: authenticationTag,
        // TODO: old code is different, check if this is correct
        // apu: removePaddingFromBase64(
        //   base64Encode(utf8.encode(didDoc.verificationMethod[0].id)),
        // ),
      );
    }

    throw UnsupportedKeyWrappingAlgorithmError(keyWrappingAlgorithm);
  }

  static Ecdh _createForXCurve({
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required JweHeader jweHeader,
    required Uint8List ephemeralPrivateKeyBytes,
    required Jwk jwk,
    required Uint8List authenticationTag,
  }) {
    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdhEs) {
      return EcdhEsForSecpAndP(
        jweHeader: jweHeader,
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        publicKey: jwk.toPublicKeyFromPoint(),
      );
    }

    if (keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      final receiverPublicKeyBytes = jwk.toPublicKeyFromPoint().toBytes();

      return Ecdh1PuForX(
        jweHeader: jweHeader,
        publicKeyBytes1: receiverPublicKeyBytes,
        publicKeyBytes2: receiverPublicKeyBytes,
        privateKeyBytes1: ephemeralPrivateKeyBytes,
        authenticationTag: authenticationTag,
        // TODO: old code is different, check if this is correct
        // apu: removePaddingFromBase64(
        //   base64Encode(utf8.encode(x25519DidDoc.verificationMethod[0].id)),
        // ),
      );
    }

    throw UnsupportedKeyWrappingAlgorithmError(keyWrappingAlgorithm);
  }

  Future<Uint8List> encryptData({
    required Wallet wallet,
    required String keyId,
    required Uint8List data,
  });

  Future<Uint8List> decryptData({
    required Wallet wallet,
    required String keyId,
    required Uint8List data,
  });
}
