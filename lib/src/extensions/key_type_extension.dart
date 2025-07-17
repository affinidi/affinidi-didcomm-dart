import 'package:ssi/ssi.dart' show KeyType;
import '../curves/curve_type.dart';
import '../errors/errors.dart';

/// Extension methods for [KeyType] to support mapping to encryption-capable curves.
/// ed25519 can't be used directly for encryption, so it maps to x25519.
/// The other key types map directly to their respective curves.
extension KeyTypeExtension on KeyType {
  /// Maps a [KeyType] to a compatible [CurveType] for encryption in DIDComm operations.
  ///
  /// Returns the corresponding [CurveType] for the given [KeyType]:
  /// - [KeyType.p256] maps to [CurveType.p256]
  /// - [KeyType.p384] maps to [CurveType.p384]
  /// - [KeyType.p521] maps to [CurveType.p521]
  /// - [KeyType.secp256k1] maps to [CurveType.secp256k1]
  /// - [KeyType.ed25519] maps to [CurveType.x25519] (Ed25519 keys are converted for use in X25519 operations)
  ///
  /// Throws [UnsupportedKeyTypeError] if the key type is not supported for encryption in DIDComm.
  CurveType asEncryptionCapableCurve() {
    if (this == KeyType.p256) {
      return CurveType.p256;
    }

    if (this == KeyType.p384) {
      return CurveType.p384;
    }

    if (this == KeyType.p521) {
      return CurveType.p521;
    }

    if (this == KeyType.secp256k1) {
      return CurveType.secp256k1;
    }

    if (this == KeyType.ed25519) {
      // we can't use ed25519 directly so we use similar x25519 curve
      return CurveType.x25519;
    }

    throw UnsupportedKeyTypeError(this);
  }
}
