import 'dart:typed_data';
import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

import 'ecdh_es.dart';

/// ECDH-ES key agreement implementation for X25519 keys, used in DIDComm encryption.
///
/// This class provides methods to compute encryption and decryption secrets using X25519 key material.
class EcdhEsForX extends EcdhEs {
  /// The public key bytes of the other party.
  final Uint8List publicKeyBytes;

  /// The ephemeral private key bytes (optional for decryption, required for encryption).
  final Uint8List? ephemeralPrivateKeyBytes;

  /// Constructs an [EcdhEsForX] instance.
  ///
  /// [publicKeyBytes]: The public key bytes of the other party.
  /// [ephemeralPrivateKeyBytes]: The ephemeral private key bytes (optional for decryption, required for encryption).
  /// [jweHeader]: The JWE header.
  EcdhEsForX({
    required this.publicKeyBytes,
    this.ephemeralPrivateKeyBytes,
    required super.jweHeader,
  });

  /// Computes the encryption secret for ECDH-ES using X25519 keys.
  ///
  /// Throws if [ephemeralPrivateKeyBytes] is not provided.
  /// Returns the shared secret as [Uint8List].
  @override
  Future<Uint8List> getEncryptionSecret() async {
    if (ephemeralPrivateKeyBytes == null) {
      throw ArgumentError('Private key is needed for encryption data.');
    }

    return x25519.X25519(ephemeralPrivateKeyBytes!, publicKeyBytes);
  }

  /// Computes the decryption secret for ECDH-ES using X25519 keys.
  ///
  /// [recipientKeyPair]: The recipient's key pair.
  /// Returns the shared secret as [Uint8List].
  @override
  Future<Uint8List> getDecryptionSecret({
    required KeyPair recipientKeyPair,
  }) async {
    return await recipientKeyPair.computeEcdhSecret(
      publicKeyBytes,
    );
  }
}
