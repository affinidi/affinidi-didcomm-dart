import 'package:json_annotation/json_annotation.dart';

part 'attachment_data.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AttachmentData {
  final String? jws;
  final String? hash;
  final List<Uri>? links;
  final String? base64;
  final String? json;

  AttachmentData({this.jws, this.hash, this.links, this.base64, this.json});

  factory AttachmentData.fromJson(Map<String, dynamic> json) =>
      _$AttachmentDataFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentDataToJson(this);
}
