import 'package:json_annotation/json_annotation.dart';

/// Supported elliptic curve types for DIDComm cryptography.
@JsonEnum(valueField: 'value')
enum CurveType {
  /// NIST P-256 curve (also known as secp256r1).
  p256('P-256', 32),

  /// Represents the NIST P-384 elliptic curve, also known as secp384r1.
  p384('P-384', 48),

  /// Represents the NIST P-521 elliptic curve, also known as secp521r1.
  p521('P-521', 66),

  /// SECG secp256k1 curve.
  secp256k1('secp256k1', 32),

  /// X25519 curve.
  x25519('X25519', 32);

  /// The string value of the curve, as used in JWKs and headers.
  final String value;

  /// Creates a [CurveType] with the specified [value] and [coordinateLength].
  ///
  /// [value] represents the identifier or name of the curve type.
  /// [coordinateLength] specifies the length of the curve's coordinate in bytes.
  const CurveType(this.value, this.coordinateLength);

  /// The length of the coordinate in bytes for this curve type.
  final int coordinateLength;

  /// Returns true if this curve is a P-curve or secp256k1 (used for ECDH-ES/ECDH-1PU).
  bool isSecp256OrPCurve() {
    return value.startsWith('P') || value.startsWith('secp256k');
  }

  /// Returns true if this curve is an X-curve (X25519).
  bool isXCurve() {
    return value.startsWith('X');
  }
}
