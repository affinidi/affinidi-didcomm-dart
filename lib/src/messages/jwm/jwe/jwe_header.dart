import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:json_annotation/json_annotation.dart';
import 'package:ssi/ssi.dart';

import '../../../common/crypto.dart';
import '../../../common/encoding.dart';
import '../../../curves/curve_type.dart';
import '../../../errors/errors.dart';
import '../../../extensions/extensions.dart';
import '../../algorithm_types/algorithms_types.dart';
import 'ephemeral_key.dart';
import 'ephemeral_key_type.dart';

part 'jwe_header.g.dart';

/// Represents the protected header of a JWE (JSON Web Encryption) message in DIDComm.
///
/// This header contains all cryptographic parameters required for decryption and verification
/// of a DIDComm-encrypted message, as defined in the
/// [DIDComm Messaging specification](https://identity.foundation/didcomm-messaging/spec).
///
/// Fields such as `skid`, `alg`, `enc`, `epk`, `apu`, and `apv` are critical for ECDH-1PU and ECDH-ES
/// key agreement, and their values must be constructed and validated according to the spec.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class JweHeader {
  /// The type of the JWE message. Defaults to 'application/didcomm-encrypted+json'.
  /// See: https://identity.foundation/didcomm-messaging/spec/#iana-media-types
  @JsonKey(name: 'typ')
  final String type;

  /// The subject key identifier (skid), used for ECDH-1PU key agreement.
  /// See: https://identity.foundation/didcomm-messaging/spec/#key-ids
  @JsonKey(name: 'skid')
  final String? subjectKeyId;

  /// The key wrapping algorithm (alg) used for encrypting the content encryption key.
  /// See: https://identity.foundation/didcomm-messaging/spec/#key-wrapping-algorithms
  @JsonKey(name: 'alg')
  final KeyWrappingAlgorithm keyWrappingAlgorithm;

  /// The content encryption algorithm (enc) used for encrypting the payload.
  /// See: https://identity.foundation/didcomm-messaging/spec/#curves-and-content-encryption-algorithms
  @JsonKey(name: 'enc')
  final EncryptionAlgorithm encryptionAlgorithm;

  /// The ephemeral public key (epk) used in key agreement.
  /// See: https://identity.foundation/didcomm-messaging/spec/#ecdh-1pu-key-wrapping-and-common-protected-headers
  /// and https://identity.foundation/didcomm-messaging/spec/#ecdh-es-key-wrapping-and-common-protected-headers
  @JsonKey(name: 'epk')
  final EphemeralKey ephemeralKey;

  /// Agreement PartyUInfo (apu), base64url-encoded sender key ID for ECDH-1PU.
  /// See: https://identity.foundation/didcomm-messaging/spec/#ecdh-1pu-key-wrapping-and-common-protected-headers
  @JsonKey(name: 'apu')
  final String? agreementPartyUInfo;

  /// Agreement PartyVInfo (apv), base64url-encoded hash of recipient key IDs.
  /// See: https://identity.foundation/didcomm-messaging/spec/#ecdh-1pu-key-wrapping-and-common-protected-headers
  /// and https://identity.foundation/didcomm-messaging/spec/#ecdh-es-key-wrapping-and-common-protected-headers
  @JsonKey(name: 'apv')
  final String? agreementPartyVInfo;

  /// Constructs a [JweHeader] with the given parameters.
  ///
  /// [type]: The type of the JWE message. Defaults to 'application/didcomm-encrypted+json'.
  /// [subjectKeyId]: The subject key identifier (skid), used for ECDH-1PU key agreement.
  /// [keyWrappingAlgorithm]: The key wrapping algorithm (alg) used for encrypting the content encryption key.
  /// [encryptionAlgorithm]: The content encryption algorithm (enc) used for encrypting the payload.
  /// [ephemeralKey]: The ephemeral public key (epk) used in key agreement.
  /// [agreementPartyUInfo]: Agreement PartyUInfo (apu), base64url-encoded sender key ID for ECDH-1PU.
  /// [agreementPartyVInfo]: Agreement PartyVInfo (apv), base64url-encoded hash of recipient key IDs.
  JweHeader({
    this.type = 'application/didcomm-encrypted+json',
    this.subjectKeyId,
    required this.keyWrappingAlgorithm,
    required this.encryptionAlgorithm,
    required this.ephemeralKey,
    this.agreementPartyUInfo,
    required this.agreementPartyVInfo,
  });

  /// Creates a [JweHeader] from a key type and encryption parameters.
  ///
  /// [keyType]: The key type to use to filter keys in the DID documents.
  /// [subjectKeyId]: The subject key identifier (skid), required for ECDH-1PU.
  /// [recipientDidDocuments]: The list of recipient DID Documents.
  /// [ephemeralPrivateKeyBytes]: The ephemeral private key bytes.
  /// [ephemeralPublicKeyBytes]: The ephemeral public key bytes.
  /// [keyWrappingAlgorithm]: The key wrapping algorithm (alg) used for encrypting the content encryption key.
  /// [encryptionAlgorithm]: The content encryption algorithm (enc) used for encrypting the payload.
  ///
  /// Throws [ArgumentError] if required parameters are missing.
  static Future<JweHeader> fromKeyType(
    KeyType keyType, {
    String? subjectKeyId,
    required List<DidDocument> recipientDidDocuments,
    required Uint8List ephemeralPrivateKeyBytes,
    Uint8List? ephemeralPublicKeyBytes,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required EncryptionAlgorithm encryptionAlgorithm,
  }) async {
    final curve = keyType.asEncryptionCapableCurve();

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
        keyType: keyType,
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

  /// Deserializes a [JweHeader] from JSON.
  ///
  /// [json] The JSON map to deserialize.
  factory JweHeader.fromJson(Map<String, dynamic> json) =>
      _$JweHeaderFromJson(json);

  /// Serializes this [JweHeader] to JSON.
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
        .map((document) => document.keyAgreement.firstWithCurve(curve).didKeyId)
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

      final publicKey = privateKey.publicKey;

      return EphemeralKey(
        curve: curve,
        keyType: EphemeralKeyType.ec,
        // it is important to use the correct coordinate length for the curve
        // since BigInt can be converted to bytes with length which is not always
        // the same as the curve's coordinate length
        x: publicKey.X.toBytes(length: curve.coordinateLength),
        y: publicKey.Y.toBytes(length: curve.coordinateLength),
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
