import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:ssi/ssi.dart';
import '../../common/crypto.dart';
import '../../common/encoding.dart';
import '../../errors/errors.dart';
import '../../jwks/jwks.dart';
import '../../extensions/extensions.dart';
import '../../curves/curve_type.dart';
import '../../messages/jwm/ephemeral_key_type.dart';
import '../algorithm_types/algorithms_types.dart';
import 'ephemeral_key.dart';

part 'jwe_header.g.dart';

@JsonSerializable()
class JweHeader {
  @JsonKey(name: 'typ')
  final String type;

  @JsonKey(name: 'skid')
  final String? subjectKeyId;

  @JsonKey(name: 'alg')
  final KeyWrappingAlgorithm keyWrappingAlgorithm;

  @JsonKey(name: 'enc')
  final EncryptionAlgorithm encryptionAlgorithm;

  @JsonKey(name: 'epk')
  final EphemeralKey ephemeralKey;

  @JsonKey(name: 'apu')
  final String? agreementPartyUInfo;

  @JsonKey(name: 'apv')
  final String? agreementPartyVInfo;

  JweHeader({
    this.type = 'application/didcomm-encrypted+json',
    this.subjectKeyId,
    required this.keyWrappingAlgorithm,
    required this.encryptionAlgorithm,
    required this.ephemeralKey,
    this.agreementPartyUInfo,
    required this.agreementPartyVInfo,
  });

  static Future<JweHeader> fromWalletKey(
    Wallet wallet,
    String keyId, {
    required Jwks recipientJwks,
    required Uint8List ephemeralPrivateKeyBytes,
    Uint8List? ephemeralPublicKeyBytes,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    final (subjectKeyId, curve, senderPublicKey) = await _buildHeaderParts(
      wallet,
      keyId,
    );

    return JweHeader(
      subjectKeyId: subjectKeyId,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
      ephemeralKey: _buildEphemeralKey(
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        ephemeralPublicKeyBytes: ephemeralPublicKeyBytes,
        senderPublicKey: senderPublicKey,
        curve: curve,
      ),
      agreementPartyVInfo: _buildAgreementPartyVInfo(recipientJwks, curve),
      agreementPartyUInfo: _buildAgreementPartyUInfo(
        keyWrappingAlgorithm,
        subjectKeyId,
      ),
    );
  }

  factory JweHeader.fromJson(Map<String, dynamic> json) =>
      _$JweHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$JweHeaderToJson(this);

  String resolveSubjectKeyId() {
    if (subjectKeyId != null) {
      return subjectKeyId!;
    }

    if (agreementPartyUInfo != null) {
      return base64DecodeToUtf8(agreementPartyUInfo!);
    }

    throw Exception('Ether skid or apu is required');
  }

  static Future<(String, CurveType, PublicKey)> _buildHeaderParts(
    Wallet wallet,
    String keyId,
  ) async {
    final publicKey = await wallet.getPublicKey(keyId);
    final curve = publicKey.type.asDidcommCurve();
    final DidDocument didDocument;

    if (curve.isSecp256OrPCurve()) {
      didDocument = DidKey.generateDocument(publicKey);
    } else if (curve.isXCurve()) {
      // TODO: revisit wallet casting
      if (wallet is! Bip32Ed25519Wallet) {
        throw Exception('Wallet must be Bip32Ed25519Wallet for X curve');
      }

      final x25519PublicKey = await wallet.getX25519PublicKey(keyId);

      didDocument = DidKey.generateDocument(
        PublicKey(keyId, x25519PublicKey, KeyType.x25519),
      );
    } else {
      throw UnsupportedCurveError(curve);
    }

    // TODO: revisit taking the first key agreement
    // TODO: key arrangement can be a string https://identity.foundation/didcomm-messaging/spec/#key-ids
    final subjectKeyId = didDocument.keyAgreement.first.id;
    return (subjectKeyId, curve, publicKey);
  }

  static String _buildAgreementPartyVInfo(Jwks jwks, CurveType curve) {
    final receiverKeyIds = _getKeyIds(jwks, curve);
    final keyIdString = receiverKeyIds.join('.');

    if (keyIdString.isEmpty) {
      throw Exception('Cant find keys with matching crv parameter');
    }

    return base64UrlEncodeNoPadding(
      sha256.convert(utf8.encode(keyIdString)).bytes,
    );
  }

  static List<String> _getKeyIds(Jwks jwks, CurveType curve) {
    final receiverKeyIds =
        jwks.keys
            .where((key) => key.curve == curve)
            .map((key) => key.keyId)
            .toList();

    receiverKeyIds.sort();
    return receiverKeyIds;
  }

  static EphemeralKey _buildEphemeralKey({
    required Uint8List ephemeralPrivateKeyBytes,
    Uint8List? ephemeralPublicKeyBytes,
    required PublicKey senderPublicKey,
    required CurveType curve,
  }) {
    if (curve.isSecp256OrPCurve()) {
      final privateKey = getPrivateKeyFromBytes(
        ephemeralPrivateKeyBytes,
        keyType: senderPublicKey.type,
      );

      final crvPoint = getPublicKeyPoint(privateKey.publicKey);
      return EphemeralKey(
        curve: curve,
        keyType: EphemeralKeyType.ec,
        x: crvPoint.x,
        y: crvPoint.y,
      );
    }

    if (curve.isXCurve()) {
      if (ephemeralPublicKeyBytes == null) {
        throw Exception('ephemeralPublicKeyBytes is required for X curve');
      }

      final x = base64UrlEncodeNoPadding(ephemeralPublicKeyBytes.toList());
      return EphemeralKey(curve: curve, keyType: EphemeralKeyType.okp, x: x);
    }

    throw UnsupportedCurveError(curve);
  }

  static String? _buildAgreementPartyUInfo(
    KeyWrappingAlgorithm keyWrapAlgorithm,
    String keyId,
  ) {
    return keyWrapAlgorithm == KeyWrappingAlgorithm.ecdh1PU
        ? base64UrlEncodeNoPadding(utf8.encode(keyId))
        : null;
  }
}
