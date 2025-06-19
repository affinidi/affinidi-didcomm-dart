import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:ssi/ssi.dart';

import '../../didcomm.dart';

enum _WalletMetaType {
  didKeyIdToKeyId,
}

extension WalletExtension on Wallet {
  Future<Uint8List> computeEcdhSecret({
    required String keyId,
    required Uint8List othersPublicKeyBytes,
  }) async {
    final keyPair = await generateKey(
      keyId: keyId,
    );

    if (keyPair is P256KeyPair) {
      return await keyPair.computeEcdhSecret(othersPublicKeyBytes);
    }

    if (keyPair is Ed25519KeyPair) {
      return await keyPair.computeEcdhSecret(othersPublicKeyBytes);
    }

    if (keyPair is Secp256k1KeyPair) {
      return await keyPair.computeEcdhSecret(othersPublicKeyBytes);
    }

    // TODO: add secp from the latest SSI package
    throw UnsupportedKeyTypeError(keyPair.publicKey.type);
  }

  static final Map<Wallet, Map<_WalletMetaType, Map<String, String>>>
      _walletsMeta = {};

  void linkDidKeyIdKeyWithKeyId(String didKeyId, String keyId) {
    _walletsMeta[this] = _walletsMeta[this] ?? {};
    _walletsMeta[this]![_WalletMetaType.didKeyIdToKeyId] =
        _walletsMeta[this]![_WalletMetaType.didKeyIdToKeyId] ?? {};

    _walletsMeta[this]![_WalletMetaType.didKeyIdToKeyId]![didKeyId] = keyId;
  }

  String? getKeyIdByDidKeyId(String didKeyId) {
    return _walletsMeta[this]?[_WalletMetaType.didKeyIdToKeyId]?[didKeyId];
  }

  String? getDidIdByKeyId(String keyId) {
    return _walletsMeta[this]?[_WalletMetaType.didKeyIdToKeyId]
        ?.entries
        .firstWhereOrNull((entry) => entry.value == keyId)
        ?.key;
  }
}
