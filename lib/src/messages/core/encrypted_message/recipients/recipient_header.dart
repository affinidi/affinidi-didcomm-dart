import 'package:json_annotation/json_annotation.dart';

part 'recipient_header.g.dart';

/// Represents the recipient header for a JWE recipient in DIDComm messages.
///
/// See [DIDComm Messaging Spec, DIDComm Encrypted Messages](https://identity.foundation/didcomm-messaging/spec/#didcomm-encrypted-messages)
/// for details.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RecipientHeader {
  /// The key identifier ("kid") for the recipient's public key.
  @JsonKey(name: 'kid')
  final String keyId;

  /// Constructs a [RecipientHeader].
  ///
  /// [keyId]: The key identifier for the recipient's public key.
  RecipientHeader({required this.keyId});

  /// Creates a [RecipientHeader] from a JSON map.
  ///
  /// [json]: The JSON map representing the recipient header.
  factory RecipientHeader.fromJson(Map<String, dynamic> json) =>
      _$RecipientHeaderFromJson(json);

  /// Converts this [RecipientHeader] to a JSON map.
  Map<String, dynamic> toJson() => _$RecipientHeaderToJson(this);
}
