import 'dart:typed_data';

import 'package:ssi/ssi.dart';
import 'package:crypto_keys_plus/crypto_keys.dart' as ck;
import 'package:elliptic/elliptic.dart' as ec;
import 'package:x25519/x25519.dart' as x25519;

import '../errors/errors.dart';
import '../messages/algorithm_types/algorithms_types.dart';
import '../messages/jwm/jwe_header.dart';

({Uint8List privateKeyBytes, Uint8List? publicKeyBytes})
generateEphemeralKeyPair(KeyType keyType) {
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

Future<Uint8List> encryptAsymmetricWithWalletKey(
  Uint8List data, {
  required Wallet wallet,
  required String keyId,
  required Map<String, dynamic> recipientPublicKeyJwk,
  required KeyWrappingAlgorithm keyWrappingAlgorithm,
  required Uint8List ephemeralPrivateKeyBytes,
  required JweHeader jweHeader,
}) async {
  return Uint8List(0);
  // final publicKey = await wallet.getPublicKey(keyId);
  // final keyPair = await wallet.getKeyPair(keyId);

  // late ECDHES ecdhProfile;
  // if (isSecp256OrPCurve(jweHeader.epk['crv'])) {
  //   ec.PublicKey recipientPublicKey = publicKeyFromPoint(
  //     curve: getEllipticCurveByPublicKey(publicKey),
  //     x: recipientPublicKeyJwk['x'],
  //     y: recipientPublicKeyJwk['y'],
  //   );

  //   ecdhProfile = ECDHES_Elliptic(
  //     privateKeyBytes: epkPrivateKey,
  //     publicKey: recipientPublicKey,
  //     apv: jweHeader.apv,
  //     enc: jweHeader.enc,
  //   );
  // } else if (isXCurve(jweHeader.epk['crv'])) {
  //   ecdhProfile = ECDHES_X25519(
  //     privateKey: epkPrivateKey,
  //     publicKey: publicKeyBytesFromJwk(recipientPublicKeyJwk),
  //     apv: jweHeader.apv,
  //     enc: jweHeader.enc,
  //   );
  // } else {
  //   throw Exception('Curve "${jweHeader.epk['crv']}" not supported.');
  // }

  // return wallet.encrypt(
  //   data,
  //   keyId: keyId,
  //   publicKey: publicKeyBytesFromJwk(recipientPublicKeyJwk),
  //   ecdhProfile: ecdhProfile,
  // );
}

// static Future<Uint8List> _encryptCekUsingECDH_1PU(ck.SymmetricKey cek,
//     {required Wallet wallet,
//     required String keyId,
//     required Map<String, dynamic> recipientPublicKeyJwk,
//     required PublicKey publicKey,
//     required Uint8List authenticationTag,
//     required KeyWrapAlgorithm keyWrapAlgorithm,
//     required JweHeader jweHeader,
//     required Uint8List epkPrivateKey}) async {
//   final didDoc = DidKey.generateDocument(publicKey);

//   if (isSecp256OrPCurve(recipientPublicKeyJwk['crv'])) {
//     final curve = getEllipticCurveByPublicKey(publicKey);
//     final receiverPubKey = publicKeyFromPoint(
//       curve: curve,
//       x: recipientPublicKeyJwk['x'],
//       y: recipientPublicKeyJwk['y'],
//     );

//     final ecdh1pu = ECDH1PU_Elliptic(
//         authenticationTag: authenticationTag,
//         keyWrapAlgorithm: keyWrapAlgorithm,
//         apu: removePaddingFromBase64(
//             base64Encode(utf8.encode(didDoc.verificationMethod[0].id))),
//         apv: jweHeader.apv,
//         public1: receiverPubKey,
//         public2: receiverPubKey,
//         private1: ec.PrivateKey.fromBytes(curve, epkPrivateKey));

//     return wallet.encrypt(cek.keyValue,
//         keyId: keyId,
//         publicKey: hexToBytes(receiverPubKey.toCompressedHex()),
//         ecdhProfile: ecdh1pu);
//   } else if (isXCurve(recipientPublicKeyJwk['crv'])) {
//     final receiverPubKeyBytes = publicKeyBytesFromJwk(recipientPublicKeyJwk);

//     final x25519DidDoc =
//         await getDidDocumentForX25519Key(wallet as Bip32Ed25519Wallet, keyId);

//     final ecdh1pu = ECDH1PU_X25519(
//         authenticationTag: authenticationTag,
//         keyWrapAlgorithm: keyWrapAlgorithm,
//         apu: removePaddingFromBase64(
//             base64Encode(utf8.encode(x25519DidDoc.verificationMethod[0].id))),
//         apv: jweHeader.apv,
//         public1: receiverPubKeyBytes,
//         public2: receiverPubKeyBytes,
//         private1: epkPrivateKey);

//     return wallet.encrypt(cek.keyValue,
//         keyId: keyId, publicKey: receiverPubKeyBytes, ecdhProfile: ecdh1pu);
//   } else {
//     throw Exception('Curve "${recipientPublicKeyJwk['crv']}" not supported');
//   }
// }

// late Uint8List encryptedCek;
// if (keyWrapAlgorithm == KeyWrapAlgorithm.ecdhES) {
//   encryptedCek = await _encryptCekUsingECDH_ES(
//     cek,
//     wallet: wallet,
//     keyId: keyId,
//     recipientPublicKeyJwk: recipientPublicKeyJwk,
//     publicKey: publicKey,
//     epkPrivateKey: epkPrivateKey,
//     jweHeader: jweHeader,
//   );
// } else if (keyWrapAlgorithm == KeyWrapAlgorithm.ecdh1PU) {
//   encryptedCek = await _encryptCekUsingECDH_1PU(
//     cek,
//     wallet: wallet,
//     keyId: keyId,
//     recipientPublicKeyJwk: recipientPublicKeyJwk,
//     publicKey: publicKey,
//     jweHeader: jweHeader,
//     epkPrivateKey: epkPrivateKey,
//     authenticationTag: authenticationTag,
//     keyWrapAlgorithm: keyWrapAlgorithm,
//   );
// } else {
//   throw Exception('Key wrap algorithm "$keyWrapAlgorithm" not supported');
// }
// );
