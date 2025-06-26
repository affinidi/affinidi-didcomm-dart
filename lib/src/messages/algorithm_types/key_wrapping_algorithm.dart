import 'package:json_annotation/json_annotation.dart';

/// Supported key wrapping algorithms for DIDComm encryption as defined in
/// [DIDComm Messaging Spec, Key Wrapping Algorithms](https://identity.foundation/didcomm-messaging/spec/#key-wrapping-algorithms).
@JsonEnum(valueField: 'value')
enum KeyWrappingAlgorithm {
  /// ECDH-ES with AES Key Wrap (A256KW).
  ecdhEs('ECDH-ES+A256KW'),

  /// ECDH-1PU with AES Key Wrap (A256KW).
  ecdh1Pu('ECDH-1PU+A256KW');

  /// The string value of the key wrapping algorithm, as used in JWE headers.
  final String value;

  /// Constructs a [KeyWrappingAlgorithm] enum value.
  ///
  /// [value]: The string representation of the algorithm.
  const KeyWrappingAlgorithm(this.value);
}
