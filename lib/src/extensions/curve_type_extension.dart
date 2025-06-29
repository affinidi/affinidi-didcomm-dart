import 'package:ssi/ssi.dart';

import '../../didcomm.dart';
import '../curves/curve_type.dart';

/// Extension methods for [CurveType] to support mapping to a compatible [KeyType].
extension CurveTypeExtension on CurveType {
  /// Maps a [CurveType] to a compatible [KeyType] for DIDComm operations.
  ///
  /// Returns the corresponding [KeyType] for the given [CurveType]:
  /// - [CurveType.p256] maps to [KeyType.p256]
  /// - [CurveType.secp256k1] maps to [KeyType.secp256k1]
  /// - [CurveType.x25519] maps to [KeyType.ed25519] (X25519 keys are derived from Ed25519 keys in DIDComm)
  ///
  /// Throws [UnsupportedCurveError] if the curve is not supported for mapping to a [KeyType].
  KeyType asKeyType() {
    if (this == CurveType.p256) {
      return KeyType.p256;
    }
    if (this == CurveType.secp256k1) {
      return KeyType.secp256k1;
    }
    if (this == CurveType.x25519) {
      // In DIDComm, X25519 keys are derived from Ed25519 keys for key agreement
      return KeyType.ed25519;
    }

    throw UnsupportedCurveError(this);
  }
}
