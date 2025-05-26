import 'dart:typed_data';

import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

import '../../extensions/extensions.dart';
import 'ecdh_1pu.dart';

class Ecdh1PuForX extends Ecdh1Pu {
  final Uint8List publicKeyBytes1;
  final Uint8List publicKeyBytes2;
  final Uint8List? privateKeyBytes1;

  Ecdh1PuForX({
    required super.authenticationTag,
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
