import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:ssi/ssi.dart';

import '../../../common/crypto.dart';
import '../../../common/encoding.dart';
import '../../../errors/errors.dart';
import '../../../extensions/extensions.dart';
import '../../../curves/curve_type.dart';
import 'ephemeral_key_type.dart';
import '../../algorithm_types/algorithms_types.dart';
import 'ephemeral_key.dart';

part 'jwe_header.g.dart';

@JsonSerializable(includeIfNull: false)
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

  static Future<JweHeader> fromKeyPair(
    KeyPair keyPair, {
    String? subjectKeyId,
    required List<DidDocument> recipientDidDocuments,
    required Uint8List ephemeralPrivateKeyBytes,
    Uint8List? ephemeralPublicKeyBytes,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    final curve = keyPair.publicKey.type.asDidcommCompatibleCurve();

    if (subjectKeyId == null &&
        keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu) {
      throw ArgumentError(
        'subjectKeyId is required for ${KeyWrappingAlgorithm.ecdh1Pu.value}',
      );
    }

    return JweHeader(
      subjectKeyId: keyWrappingAlgorithm == KeyWrappingAlgorithm.ecdh1Pu
          ? subjectKeyId
          : null,
      keyWrappingAlgorithm: keyWrappingAlgorithm,
      encryptionAlgorithm: encryptionAlgorithm,
      ephemeralKey: _buildEphemeralKey(
        ephemeralPrivateKeyBytes: ephemeralPrivateKeyBytes,
        ephemeralPublicKeyBytes: ephemeralPublicKeyBytes,
        keyType: keyPair.publicKey.type,
        curve: curve,
      ),
      agreementPartyVInfo:
          _buildAgreementPartyVInfo(recipientDidDocuments, curve),
      agreementPartyUInfo: _buildAgreementPartyUInfo(
        keyWrappingAlgorithm,
        subjectKeyId,
      ),
    );
  }

  factory JweHeader.fromJson(Map<String, dynamic> json) =>
      _$JweHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$JweHeaderToJson(this);

  static String _buildAgreementPartyVInfo(
    List<DidDocument> recipientDidDocuments,
    CurveType curve,
  ) {
    final receiverKeyIds = _getKeyIds(recipientDidDocuments, curve);
    final keyIdString = receiverKeyIds.join('.');

    if (keyIdString.isEmpty) {
      throw Exception('Cant find keys with matching crv parameter');
    }

    return base64UrlEncodeNoPadding(
      sha256.convert(utf8.encode(keyIdString)).bytes,
    );
  }

  static List<String> _getKeyIds(
    List<DidDocument> recipientDidDocuments,
    CurveType curve,
  ) {
    // https://identity.foundation/didcomm-messaging/spec/#ecdh-es-key-wrapping-and-common-protected-headers
    // keys merged with comma and sorted alphabetically

    final keyIdsByCurve = recipientDidDocuments
        .map((document) => document.keyAgreement.firstWithCurve(curve).id)
        .toList();

    keyIdsByCurve.sort();
    return keyIdsByCurve;
  }

  static EphemeralKey _buildEphemeralKey({
    required Uint8List ephemeralPrivateKeyBytes,
    Uint8List? ephemeralPublicKeyBytes,
    required KeyType keyType,
    required CurveType curve,
  }) {
    if (curve.isSecp256OrPCurve()) {
      final privateKey = getPrivateKeyFromBytes(
        ephemeralPrivateKeyBytes,
        keyType: keyType,
      );

      return EphemeralKey(
        curve: curve,
        keyType: EphemeralKeyType.ec,
        x: privateKey.publicKey.X.toBytes(),
        y: privateKey.publicKey.Y.toBytes(),
      );
    }

    if (curve.isXCurve()) {
      if (ephemeralPublicKeyBytes == null) {
        throw Exception('ephemeralPublicKeyBytes is required for X curve');
      }

      return EphemeralKey(
        curve: curve,
        keyType: EphemeralKeyType.okp,
        x: ephemeralPublicKeyBytes,
      );
    }

    throw UnsupportedCurveError(curve);
  }

  static String? _buildAgreementPartyUInfo(
    KeyWrappingAlgorithm keyWrapAlgorithm,
    String? subjectKeyId,
  ) {
    if (keyWrapAlgorithm == KeyWrappingAlgorithm.ecdh1Pu &&
        subjectKeyId == null) {
      throw ArgumentError(
        'subjectKeyId is required for ${KeyWrappingAlgorithm.ecdh1Pu.value}',
        'subjectKeyId',
      );
    }

    return keyWrapAlgorithm == KeyWrappingAlgorithm.ecdh1Pu
        ? base64UrlEncodeNoPadding(utf8.encode(subjectKeyId!))
        : null;
  }
}
