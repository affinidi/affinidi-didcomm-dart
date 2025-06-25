import 'package:json_annotation/json_annotation.dart';
import '../../didcomm_message.dart';

part 'ping_message.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PingMessage extends DidcommMessage {
  PingMessage();

  factory PingMessage.fromJson(Map<String, dynamic> json) =>
      _$PingMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PingMessageToJson(this);
}
