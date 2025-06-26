import 'package:json_annotation/json_annotation.dart';

/// The type of ephemeral key used in DIDComm JWE headers for encrypted messages.
///
/// - [ec]: Elliptic Curve (EC) key, used for curves like P-256, P-384, P-521, secp256k1.
/// - [okp]: Octet Key Pair (OKP), used for curves like X25519.
@JsonEnum(valueField: 'value')
enum EphemeralKeyType {
  /// Elliptic Curve (EC) key type.
  ec('EC'),

  /// Octet Key Pair (OKP) key type.
  okp('OKP');

  /// The string value as used in JWE headers.
  final String value;

  /// Constructs an [EphemeralKeyType] with the given string [value].
  const EphemeralKeyType(this.value);
}
