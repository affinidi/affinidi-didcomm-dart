import 'package:didcomm/src/annotations/own_json_properties.dart';
import 'package:didcomm/src/messages/attachments/attachment.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../converters/epoch_seconds_converter.dart';
import '../didcomm_message.dart';

part 'plaintext_message.g.dart';
part 'plaintext_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false)
class PlaintextMessage extends DidcommMessage {
  final String id;
  final Uri type;
  final String? from;
  final List<String>? to;

  @JsonKey(name: 'thid')
  final String? threadId;

  @JsonKey(name: 'pthid')
  final String? parentThreadId;

  @JsonKey(name: 'created_time')
  @EpochSecondsConverter()
  final DateTime? createdTime;

  @JsonKey(name: 'expires_time')
  @EpochSecondsConverter()
  final DateTime? expiresTime;

  final Map<String, dynamic>? body;
  final List<Attachment>? attachments;

  PlaintextMessage({
    required this.id,
    required this.type,
    this.from,
    this.to,
    this.threadId,
    this.parentThreadId,
    this.createdTime,
    this.expiresTime,
    this.body,
    this.attachments,
  });

  factory PlaintextMessage.fromJson(Map<String, dynamic> json) {
    final message = _$PlaintextMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$PlaintextMessageToJson(this));
}
