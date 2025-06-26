import 'package:json_annotation/json_annotation.dart';

part 'attachment_data.g.dart';

/// Data container for a DIDComm attachment, as defined in the
/// [DIDComm Messaging specification](https://identity.foundation/didcomm-messaging/spec/#attachments).
///
/// The `AttachmentData` object provides multiple ways to represent the content of an attachment:
///
/// - [jws]: A [JWS](https://tools.ietf.org/html/rfc7515) in detached content mode, allowing the attachment to be signed. The signature need not come from the author of the message.
/// - [hash]: The hash of the content, encoded in multi-hash format. Used as an integrity check, and MUST be used if the data is referenced via [links].
/// - [links]: A list of URIs where the content can be fetched. Allows content to be attached by reference instead of by value.
/// - [base64]: Base64url-encoded data, for representing arbitrary content inline instead of via [links].
/// - [json]: Directly embedded JSON data, for content that is natively conveyable as JSON.
///
/// See: https://identity.foundation/didcomm-messaging/spec/#attachments
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AttachmentData {
  /// A JWS (JSON Web Signature) in detached content mode, allowing the attachment to be signed.
  /// The signature need not come from the author of the message.
  /// See: https://identity.foundation/didcomm-messaging/spec/#attachments
  final String? jws;

  /// The hash of the content, encoded in multi-hash format. Used as an integrity check for the attachment.
  /// MUST be used if the data is referenced via [links].
  final String? hash;

  /// A list of URIs where the content can be fetched. Allows content to be attached by reference instead of by value.
  final List<Uri>? links;

  /// Base64url-encoded data, for representing arbitrary content inline instead of via [links].
  final String? base64;

  /// Directly embedded JSON data, for content that is natively conveyable as JSON.
  final String? json;

  /// Creates an [AttachmentData] instance.
  ///
  /// All parameters are optional and correspond to the different ways attachment data can be represented.
  ///
  /// [jws] - JWS signature for the attachment.
  /// [hash] - Hash of the attachment content (multi-hash format).
  /// [links] - List of URIs to fetch the content.
  /// [base64] - Base64url-encoded inline content.
  /// [json] - Inline JSON content.
  AttachmentData({this.jws, this.hash, this.links, this.base64, this.json});

  /// Creates an [AttachmentData] instance from a JSON map.
  ///
  /// [json] - The JSON map containing the attachment data fields.
  factory AttachmentData.fromJson(Map<String, dynamic> json) =>
      _$AttachmentDataFromJson(json);

  /// Converts this [AttachmentData] instance to a JSON map.
  Map<String, dynamic> toJson() => _$AttachmentDataToJson(this);
}
