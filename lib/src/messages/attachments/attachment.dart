import 'package:json_annotation/json_annotation.dart';

import '../../converters/epoch_seconds_converter.dart';
import 'attachment_data.dart';

part 'attachment.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Attachment {
  final String? id;
  final String? description;
  final String? filename;

  @JsonKey(name: 'media_type')
  final String? mediaType;

  final String? format;

  @JsonKey(name: 'lastmod_time')
  @EpochSecondsConverter()
  final DateTime? lastModifiedTime;

  final AttachmentData? data;

  @JsonKey(name: 'byte_count')
  final int? byteCount;

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

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentToJson(this);
}
