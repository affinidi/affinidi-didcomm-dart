import 'dart:typed_data';

import 'package:elliptic/ecdh.dart' as ecdh;
import 'package:elliptic/elliptic.dart' as ec;
import 'package:ssi/ssi.dart';

import '../../extensions/extensions.dart';
import 'ecdh_1pu.dart';

/// ECDH-1PU key agreement implementation for secp256k1 and P-256 curves, used in DIDComm encryption.
///
/// This class provides methods to compute encryption and decryption secrets using secp256k1 or P-256 key material.
class Ecdh1PuForSecp256AndP extends Ecdh1Pu {
  /// The public key of the first party.
  final ec.PublicKey publicKey1;

  /// The public key of the second party.
  final ec.PublicKey publicKey2;

  /// The private key of the first party (optional for decryption, required for encryption).
  final ec.PrivateKey? privateKey1;

  /// Constructs an [Ecdh1PuForSecp256AndP] instance.
  ///
  /// [authenticationTag]: The authentication tag for the JWE.
  /// [jweHeader]: The JWE header.
  /// [publicKey1]: The public key of the first party.
  /// [publicKey2]: The public key of the second party.
  /// [privateKey1]: The private key of the first party (optional for decryption, required for encryption).
  Ecdh1PuForSecp256AndP({
    required super.authenticationTag,
    required super.jweHeader,
    required this.publicKey1,
    required this.publicKey2,
    this.privateKey1,
  });

  /// Computes the encryption secrets (ze, zs) for ECDH-1PU using secp256k1 or P-256 keys.
  ///
  /// [senderKeyPair]: The sender's key pair.
  /// Throws if [privateKey1] is not provided.
  /// Returns a tuple containing [ze] and [zs] as [Uint8List].
  @override
  Future<({Uint8List ze, Uint8List zs})> getEncryptionSecrets({
    required KeyPair senderKeyPair,
  }) async {
    if (privateKey1 == null) {
      throw Exception('privateKey1 is required for encryption data');
    }

    final ze = ecdh.computeSecret(privateKey1!, publicKey1);
    final zs = await senderKeyPair.computeEcdhSecret(
      publicKey2.toBytes(),
    );

    return (ze: Uint8List.fromList(ze), zs: Uint8List.fromList(zs));
  }

  /// Computes the decryption secrets (ze, zs) for ECDH-1PU using secp256k1 or P-256 keys.
  ///
  /// [recipientKeyPair]: The recipient's key pair.
  /// Returns a tuple containing [ze] and [zs] as [Uint8List].
  @override
  Future<({Uint8List ze, Uint8List zs})> getDecryptionSecrets({
    required KeyPair recipientKeyPair,
  }) async {
    final ze = await recipientKeyPair.computeEcdhSecret(
      publicKey1.toBytes(),
    );

    final zs = await recipientKeyPair.computeEcdhSecret(
      publicKey2.toBytes(),
    );

    return (ze: Uint8List.fromList(ze), zs: Uint8List.fromList(zs));
  }
}
