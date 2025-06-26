import 'package:json_annotation/json_annotation.dart';

import '../../converters/epoch_seconds_converter.dart';
import 'attachment_data.dart';

part 'attachment.g.dart';

/// Represents an attachment in a DIDComm plaintext message, as defined in the
/// [DIDComm Messaging specification](https://identity.foundation/didcomm-messaging/spec/#attachments).
///
/// Attachments allow DIDComm messages to include additional content such as documents,
/// images, or other media, either embedded or by reference. See the spec for details
/// on each field's semantics and usage.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Attachment {
  /// Identifies attached content within the scope of a given message.
  /// Should be brief and consist of unreserved URI characters.
  final String? id;

  /// A human-readable description of the attachment content.
  final String? description;

  /// A hint about the name that might be used if this attachment is persisted as a file.
  /// If present and [mediaType] is not, the extension may be used to infer a MIME type.
  final String? filename;

  /// Describes the media type (MIME type) of the attached content.
  @JsonKey(name: 'media_type')
  final String? mediaType;

  /// Further describes the format of the attachment if [mediaType] is not sufficient.
  final String? format;

  /// A hint about when the content in this attachment was last modified.
  /// Serialized/deserialized as seconds since the Unix epoch (UTC).
  @JsonKey(name: 'lastmod_time')
  @EpochSecondsConverter()
  final DateTime? lastModifiedTime;

  /// The data payload of the attachment, which may be embedded or referenced.
  /// See [AttachmentData] for supported representations.
  final AttachmentData? data;

  /// The size of the attachment in bytes, useful when content is included by reference.
  @JsonKey(name: 'byte_count')
  final int? byteCount;

  /// Creates a new [Attachment].
  ///
  /// [id] - Unique identifier for the attachment.
  /// [description] - Human-readable description.
  /// [filename] - File name hint.
  /// [mediaType] - MIME type of the content.
  /// [format] - Further format description.
  /// [lastModifiedTime] - Last modification time.
  /// [data] - The attachment data (see [AttachmentData]).
  /// [byteCount] - Size in bytes (for reference attachments).
  Attachment({
    this.id,
    this.description,
    this.filename,
    this.mediaType,
    this.format,
    this.lastModifiedTime,
    this.data,
    this.byteCount,
  });

  /// Creates an [Attachment] from a JSON map.
  ///
  /// [json] - The JSON map to parse.
  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);

  /// Converts this [Attachment] to a JSON map.
  Map<String, dynamic> toJson() => _$AttachmentToJson(this);
}
