import 'package:json_annotation/json_annotation.dart';
import '../../didcomm_message.dart';

part 'ack_message.g.dart';

@JsonSerializable(includeIfNull: false)
class AckMessage extends DidcommMessage {
  AckMessage();

  factory AckMessage.fromJson(Map<String, dynamic> json) =>
      _$AckMessageFromJson(json);

  Map<String, dynamic> toJson() => _$AckMessageToJson(this);
}
