import 'package:json_annotation/json_annotation.dart';

/// Supported content encryption algorithms for DIDComm encryption as defined in
/// [DIDComm Messaging Spec, Curves and Content Encryption Algorithms](https://identity.foundation/didcomm-messaging/spec/#curves-and-content-encryption-algorithms).
@JsonEnum(valueField: 'value')
enum EncryptionAlgorithm {
  /// AES-256-CBC with HMAC-SHA-512.
  a256cbc('A256CBC-HS512'),

  /// AES-256-GCM.
  a256gcm('A256GCM');

  /// The string value of the encryption algorithm, as used in JWE headers.
  final String value;

  /// Constructs an [EncryptionAlgorithm] enum value.
  ///
  /// [value]: The string representation of the algorithm.
  const EncryptionAlgorithm(this.value);
}
