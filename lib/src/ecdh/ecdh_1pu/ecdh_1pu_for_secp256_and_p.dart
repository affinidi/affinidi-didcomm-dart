import 'dart:typed_data';

import 'package:elliptic/elliptic.dart' as ec;
import 'package:elliptic/ecdh.dart' as ecdh;
import 'package:ssi/ssi.dart';

import '../../extensions/extensions.dart';
import 'ecdh_1pu.dart';

class Ecdh1PuForSecp256AndP extends Ecdh1Pu {
  final ec.PublicKey publicKey1;
  final ec.PublicKey publicKey2;
  final ec.PrivateKey? privateKey1;

  Ecdh1PuForSecp256AndP({
    required super.authenticationTag,
    required super.jweHeader,
    required this.publicKey1,
    required this.publicKey2,
    this.privateKey1,
  });

  @override
  Future<({Uint8List ze, Uint8List zs})> getEncryptionSecrets({
    required Wallet senderWallet,
    required String senderKeyId,
  }) async {
    if (privateKey1 == null) {
      throw Exception('privateKey1 is required for encryption data');
    }

    final ze = ecdh.computeSecret(privateKey1!, publicKey1);
    final zs = await senderWallet.computeEcdhSecret(
      keyId: senderKeyId,
      othersPublicKeyBytes: publicKey2.toBytes(),
    );

    return (ze: Uint8List.fromList(ze), zs: Uint8List.fromList(zs));
  }

  @override
  Future<({Uint8List ze, Uint8List zs})> getDecryptionSecrets({
    required Wallet recipientWallet,
    required String recipientKeyId,
  }) async {
    final ze = await recipientWallet.computeEcdhSecret(
      keyId: recipientKeyId,
      othersPublicKeyBytes: publicKey1.toBytes(),
    );

    final zs = await recipientWallet.computeEcdhSecret(
      keyId: recipientKeyId,
      othersPublicKeyBytes: publicKey2.toBytes(),
    );

    return (ze: Uint8List.fromList(ze), zs: Uint8List.fromList(zs));
  }
}
