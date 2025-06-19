import 'dart:typed_data';
import 'package:elliptic/ecdh.dart' as ecdh;
import 'package:elliptic/elliptic.dart' as ec;
import 'package:ssi/ssi.dart';

import '../../extensions/extensions.dart';
import 'ecdh_es.dart';

class EcdhEsForSecpAndP extends EcdhEs {
  final ec.PublicKey publicKey;
  final Uint8List? ephemeralPrivateKeyBytes;

  EcdhEsForSecpAndP({
    required this.publicKey,
    this.ephemeralPrivateKeyBytes,
    required super.jweHeader,
  });

  @override
  Future<Uint8List> getEncryptionSecret() async {
    if (ephemeralPrivateKeyBytes == null) {
      throw Exception('Private key needed for encryption data.');
    }

    final privateKey = ec.PrivateKey.fromBytes(
      publicKey.curve,
      ephemeralPrivateKeyBytes!,
    );

    return Uint8List.fromList(ecdh.computeSecret(privateKey, publicKey));
  }

  @override
  Future<Uint8List> getDecryptionSecret({
    required KeyPair recipientKeyPair,
  }) async {
    return await recipientKeyPair.computeEcdhSecret(
      publicKey.toBytes(),
    );
  }
}
