import 'package:json_annotation/json_annotation.dart';

part 'jws_header.g.dart';

/// Represents the protected header of a JWS (JSON Web Signature) message in a DIDComm signed message.
/// It is integrity-protected - included in the signature.
///
/// This header contains cryptographic parameters required for signature verification,
/// as described in the [DIDComm Messaging specification](https://identity.foundation/didcomm-messaging/spec/#message-signing).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class JwsHeader {
  /// The algorithm used for the JWS signature (e.g., "EdDSA", "ES256").
  /// See: https://identity.foundation/didcomm-messaging/spec/#algorithms
  @JsonKey(name: 'alg')
  final String algorithm;

  /// The elliptic curve used, if applicable (e.g., "Ed25519", "P-256").
  /// Optional, depending on the algorithm.
  @JsonKey(name: 'crv')
  final String? curve;

  /// The media type (typ) of the JWS message (e.g., "application/didcomm-signed+json").
  /// See: https://identity.foundation/didcomm-messaging/spec/#iana-media-types
  @JsonKey(name: 'typ')
  final String mimeType;

  /// Constructs a [JwsHeader] with the given parameters.
  ///
  /// [algorithm] - The signature algorithm (alg).
  /// [curve] - The elliptic curve (crv), if applicable.
  /// [mimeType] - The media type (typ) of the JWS message.
  JwsHeader({
    required this.algorithm,
    this.curve,
    required this.mimeType,
  });

  /// Creates a [JwsHeader] from a JSON map.
  ///
  /// [json] - The JSON map to parse.
  factory JwsHeader.fromJson(Map<String, dynamic> json) =>
      _$JwsHeaderFromJson(json);

  /// Converts this [JwsHeader] to a JSON map.
  Map<String, dynamic> toJson() => _$JwsHeaderToJson(this);
}
