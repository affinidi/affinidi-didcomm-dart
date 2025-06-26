import 'package:json_annotation/json_annotation.dart';

/// Supported elliptic curve types for DIDComm cryptography.
@JsonEnum(valueField: 'value')
enum CurveType {
  /// NIST P-256 curve (also known as secp256r1).
  p256('P-256'),

  /// SECG secp256k1 curve.
  secp256k1('secp256k1'),

  /// X25519 curve.
  x25519('X25519');

  /// The string value of the curve, as used in JWKs and headers.
  final String value;

  /// Constructs a [CurveType] enum value.
  ///
  /// [value]: The string representation of the curve.
  const CurveType(this.value);

  /// Returns true if this curve is a P-curve or secp256k1 (used for ECDH-ES/ECDH-1PU).
  bool isSecp256OrPCurve() {
    return value.startsWith('P') || value.startsWith('secp256k');
  }

  /// Returns true if this curve is an X-curve (X25519).
  bool isXCurve() {
    return value.startsWith('X');
  }
}
