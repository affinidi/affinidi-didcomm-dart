import 'package:json_annotation/json_annotation.dart';
import '../../didcomm_message.dart';

part 'ping_message.g.dart';

@JsonSerializable(includeIfNull: false)
class PingMessage extends DidcommMessage {
  PingMessage();

  factory PingMessage.fromJson(Map<String, dynamic> json) =>
      _$PingMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PingMessageToJson(this);
}
