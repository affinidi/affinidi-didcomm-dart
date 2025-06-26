import 'package:json_annotation/json_annotation.dart';

part 'signature_header.g.dart';

/// Represents the unprotected header for a JWS signature in DIDComm messages.
/// It is not included in the signature, meaning it can be modified by intermediaries.
///
/// The signature header contains the key identifier ("kid") used to identify the signing key.
/// See [DIDComm Messaging Spec, DIDComm Signed Messages](https://identity.foundation/didcomm-messaging/spec/#didcomm-signed-messages)
/// for details.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SignatureHeader {
  /// The key identifier ("kid") for the signing key.
  @JsonKey(name: 'kid')
  final String keyId;

  /// Constructs a [SignatureHeader].
  ///
  /// [keyId]: The key identifier for the signing key.
  SignatureHeader({required this.keyId});

  /// Creates a [SignatureHeader] from a JSON map.
  ///
  /// [json]: The JSON map representing the signature header.
  factory SignatureHeader.fromJson(Map<String, dynamic> json) =>
      _$SignatureHeaderFromJson(json);

  /// Converts this [SignatureHeader] to a JSON map.
  Map<String, dynamic> toJson() => _$SignatureHeaderToJson(this);
}
