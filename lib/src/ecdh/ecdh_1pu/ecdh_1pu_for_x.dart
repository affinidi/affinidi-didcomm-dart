import 'dart:typed_data';

import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

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
    required KeyPair senderKeyPair,
  }) async {
    if (privateKeyBytes1 == null) {
      throw Exception('Private key needed for encryption data.');
    }

    final ze = x25519.X25519(privateKeyBytes1!.sublist(0, 32), publicKeyBytes1);

    final zs = await senderKeyPair.computeEcdhSecret(
      publicKeyBytes2,
    );

    return (ze: ze, zs: zs);
  }

  @override
  Future<({Uint8List ze, Uint8List zs})> getDecryptionSecrets({
    required KeyPair recipientKeyPair,
  }) async {
    final ze = await recipientKeyPair.computeEcdhSecret(
      publicKeyBytes1,
    );

    final zs = await recipientKeyPair.computeEcdhSecret(
      publicKeyBytes2,
    );

    return (ze: ze, zs: zs);
  }
}
