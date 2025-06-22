import 'package:json_annotation/json_annotation.dart';
import '../../didcomm_message.dart';

part 'ping_response_message.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PingResponseMessage extends DidcommMessage {
  PingResponseMessage();

  factory PingResponseMessage.fromJson(Map<String, dynamic> json) =>
      _$PingResponseMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PingResponseMessageToJson(this);
}
