import 'package:ssi/ssi.dart';

import '../../didcomm.dart';

/// Extension methods for [CurveType] to support mapping to a compatible [KeyType].
extension CurveTypeExtension on CurveType {
  static final _curveToKeyTypeMap = {
    CurveType.p256: KeyType.p256,
    CurveType.p384: KeyType.p384,
    CurveType.p521: KeyType.p521,
    CurveType.secp256k1: KeyType.secp256k1,
    CurveType.x25519: KeyType.ed25519, // X25519 is derived from Ed25519
  };

  /// Maps a [CurveType] to a compatible [KeyType] for DIDComm operations.
  ///
  /// Returns the corresponding [KeyType] for the given [CurveType]:
  /// - [CurveType.p256] maps to [KeyType.p256]
  /// - [CurveType.p384] maps to [KeyType.p384]
  /// - [CurveType.p521] maps to [KeyType.p521]
  /// - [CurveType.secp256k1] maps to [KeyType.secp256k1]
  /// - [CurveType.x25519] maps to [KeyType.ed25519] (X25519 keys are derived from Ed25519 keys)
  ///
  /// Throws [UnsupportedCurveError] if the curve is not supported for mapping to a [KeyType].
  KeyType asKeyType() {
    if (_curveToKeyTypeMap.containsKey(this)) {
      return _curveToKeyTypeMap[this]!;
    }

    throw UnsupportedCurveError(this);
  }
}
