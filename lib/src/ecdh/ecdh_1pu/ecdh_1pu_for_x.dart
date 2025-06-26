import 'dart:typed_data';

import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

import 'ecdh_1pu.dart';

/// ECDH-1PU key agreement implementation for X25519 keys, used in DIDComm encryption.
///
/// This class provides methods to compute encryption and decryption secrets using X25519 key material.
class Ecdh1PuForX extends Ecdh1Pu {
  /// The public key bytes of the first party.
  final Uint8List publicKeyBytes1;

  /// The public key bytes of the second party.
  final Uint8List publicKeyBytes2;

  /// The private key bytes of the first party (optional for decryption, required for encryption).
  final Uint8List? privateKeyBytes1;

  /// Constructs an [Ecdh1PuForX] instance.
  ///
  /// [authenticationTag]: The authentication tag for the JWE.
  /// [jweHeader]: The JWE header.
  /// [publicKeyBytes1]: The public key bytes of the first party.
  /// [publicKeyBytes2]: The public key bytes of the second party.
  /// [privateKeyBytes1]: The private key bytes of the first party (optional for decryption, required for encryption).
  Ecdh1PuForX({
    required super.authenticationTag,
    required super.jweHeader,
    required this.publicKeyBytes1,
    required this.publicKeyBytes2,
    this.privateKeyBytes1,
  });

  /// Computes the encryption secrets (ze, zs) for ECDH-1PU using X25519 keys.
  ///
  /// [senderKeyPair]: The sender's key pair.
  /// Throws if [privateKeyBytes1] is not provided.
  /// Returns a tuple containing [ze] and [zs] as [Uint8List].
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

  /// Computes the decryption secrets (ze, zs) for ECDH-1PU using X25519 keys.
  ///
  /// [recipientKeyPair]: The recipient's key pair.
  /// Returns a tuple containing [ze] and [zs] as [Uint8List].
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
