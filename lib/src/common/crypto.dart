import 'dart:typed_data';

import 'package:didcomm/src/common/encoding.dart';
import 'package:ssi/ssi.dart';
import 'package:elliptic/elliptic.dart' as ec;
import 'package:x25519/x25519.dart' as x25519;
import 'package:web3dart/web3dart.dart' as c;

import '../errors/errors.dart';

({Uint8List privateKeyBytes, Uint8List? publicKeyBytes}) getEphemeralPrivateKey(
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

String getCurveByPublicKey(KeyType keyType) {
  if (keyType == KeyType.p256) {
    return 'P-256';
  } else if (keyType == KeyType.secp256k1) {
    return 'secp256k1';
  } else if (keyType == KeyType.ed25519) {
    return 'X25519';
  }

  throw UnsupportedKeyTypeError(keyType);
}

bool isSecp256OrPCurve(String crv) {
  return crv.startsWith('P') || crv.startsWith('secp256k');
}

bool isXCurve(String crv) {
  return crv.startsWith('X');
}

Uint8List _bigIntToUint8List(BigInt value, {int? length}) {
  var bytes =
      value < BigInt.zero ? c.intToBytes(value) : c.unsignedIntToBytes(value);

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
