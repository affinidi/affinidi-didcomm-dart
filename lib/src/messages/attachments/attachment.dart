import 'package:json_annotation/json_annotation.dart';

import '../../converters/epoch_seconds_converter.dart';
import 'attachment_data.dart';

part 'attachment.g.dart';

/// Represents an attachment in a DIDComm plain text message.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Attachment {
  /// The unique identifier of the attachment.
  final String? id;

  /// A human-readable description of the attachment.
  final String? description;

  /// The filename of the attachment, if applicable.
  final String? filename;

  /// The media type (MIME type) of the attachment content.
  @JsonKey(name: 'media_type')
  final String? mediaType;

  /// The format of the attachment content.
  final String? format;

  /// The last modification time of the attachment as a [DateTime].
  ///
  /// This value is serialized and deserialized using [EpochSecondsConverter],
  /// representing the time as the number of seconds since the Unix epoch (UTC).
  @JsonKey(name: 'lastmod_time')
  @EpochSecondsConverter()
  final DateTime? lastModifiedTime;

  /// The data payload of the attachment.
  final AttachmentData? data;

  /// The size of the attachment in bytes.
  @JsonKey(name: 'byte_count')
  final int? byteCount;

  /// Creates a new [Attachment].
  ///
  /// [id] is the unique identifier.
  /// [description] is a human-readable description.
  /// [filename] is the name of the file.
  /// [mediaType] is the MIME type.
  /// [format] is the content format.
  /// [lastModifiedTime] is the last modification time.
  /// [data] is the attachment data.
  /// [byteCount] is the size in bytes.
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
  /// [json] is the JSON map to parse.
  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);

  /// Converts this [Attachment] to a JSON map.
  Map<String, dynamic> toJson() => _$AttachmentToJson(this);
}
