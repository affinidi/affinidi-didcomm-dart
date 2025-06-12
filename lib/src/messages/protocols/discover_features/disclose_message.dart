import 'package:json_annotation/json_annotation.dart';
import '../../didcomm_message.dart';

part 'disclose_message.g.dart';

@JsonSerializable(includeIfNull: false)
class DiscloseMessage extends DidcommMessage {
  DiscloseMessage();

  factory DiscloseMessage.fromJson(Map<String, dynamic> json) =>
      _$DiscloseMessageFromJson(json);

  Map<String, dynamic> toJson() => _$DiscloseMessageToJson(this);
}
