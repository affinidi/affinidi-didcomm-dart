import 'package:json_annotation/json_annotation.dart';
import '../../didcomm_message.dart';

part 'forward_message.g.dart';

@JsonSerializable()
class ForwardMessage extends DidcommMessage {
  ForwardMessage();

  factory ForwardMessage.fromJson(Map<String, dynamic> json) =>
      _$ForwardMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ForwardMessageToJson(this);
}
