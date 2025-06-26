import 'dart:typed_data';
import 'package:elliptic/ecdh.dart' as ecdh;
import 'package:elliptic/elliptic.dart' as ec;
import 'package:ssi/ssi.dart';

import '../../extensions/extensions.dart';
import 'ecdh_es.dart';

/// ECDH-ES key agreement implementation for secp256k1 and P-256 curves, used in DIDComm encryption.
///
/// This class provides methods to compute encryption and decryption secrets using secp256k1 or P-256 key material.
class EcdhEsForSecpAndP extends EcdhEs {
  /// The public key of the other party.
  final ec.PublicKey publicKey;

  /// The ephemeral private key bytes (optional for decryption, required for encryption).
  final Uint8List? ephemeralPrivateKeyBytes;

  /// Constructs an [EcdhEsForSecpAndP] instance.
  ///
  /// [publicKey]: The public key of the other party.
  /// [ephemeralPrivateKeyBytes]: The ephemeral private key bytes (optional for decryption, required for encryption).
  /// [jweHeader]: The JWE header.
  EcdhEsForSecpAndP({
    required this.publicKey,
    this.ephemeralPrivateKeyBytes,
    required super.jweHeader,
  });

  /// Computes the encryption secret for ECDH-ES using secp256k1 or P-256 keys.
  ///
  /// Throws if [ephemeralPrivateKeyBytes] is not provided.
  /// Returns the shared secret as [Uint8List].
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

  /// Computes the decryption secret for ECDH-ES using secp256k1 or P-256 keys.
  ///
  /// [recipientKeyPair]: The recipient's key pair.
  /// Returns the shared secret as [Uint8List].
  @override
  Future<Uint8List> getDecryptionSecret({
    required KeyPair recipientKeyPair,
  }) async {
    return await recipientKeyPair.computeEcdhSecret(
      publicKey.toBytes(),
    );
  }
}
