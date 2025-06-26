import 'package:collection/collection.dart';
import 'package:ssi/ssi.dart';

/// Internal enum for wallet metadata types used in DIDComm key associations.
enum _WalletMetaType {
  didKeyIdToKeyId,
}

/// Extension methods for [Wallet] to support DIDComm-specific key management and lookup.
extension WalletExtension on Wallet {
  /// Internal metadata map for wallet key associations.
  static final Map<Wallet, Map<_WalletMetaType, Map<String, String>>>
      _walletsMeta = {};

  /// Links a DID key ID ([didKeyId]) with a wallet key ID ([keyId]) for lookup.
  ///
  /// [didKeyId]: The DID key identifier.
  /// [keyId]: The wallet's key identifier.
  void linkDidKeyIdKeyWithKeyId(String didKeyId, String keyId) {
    _walletsMeta[this] = _walletsMeta[this] ?? {};
    _walletsMeta[this]![_WalletMetaType.didKeyIdToKeyId] =
        _walletsMeta[this]![_WalletMetaType.didKeyIdToKeyId] ?? {};

    _walletsMeta[this]![_WalletMetaType.didKeyIdToKeyId]![didKeyId] = keyId;
  }

  /// Retrieves the wallet key ID associated with a given DID key ID ([didKeyId]).
  ///
  /// [didKeyId]: The DID key identifier.
  /// Returns the wallet key ID, or null if not found.
  String? getKeyIdByDidKeyId(String didKeyId) {
    return _walletsMeta[this]?[_WalletMetaType.didKeyIdToKeyId]?[didKeyId];
  }

  /// Retrieves the DID key ID associated with a given wallet key ID ([keyId]).
  ///
  /// [keyId]: The wallet's key identifier.
  /// Returns the DID key ID, or null if not found.
  String? getDidIdByKeyId(String keyId) {
    return _walletsMeta[this]?[_WalletMetaType.didKeyIdToKeyId]
        ?.entries
        .firstWhereOrNull((entry) => entry.value == keyId)
        ?.key;
  }
}
