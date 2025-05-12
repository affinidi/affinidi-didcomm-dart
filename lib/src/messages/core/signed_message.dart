import 'package:json_annotation/json_annotation.dart';
import '../didcomm_message.dart';

part 'signed_message.g.dart';

@JsonSerializable()
class SignedMessage extends DidcommMessage {
  SignedMessage();

  factory SignedMessage.fromJson(Map<String, dynamic> json) =>
      _$SignedMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SignedMessageToJson(this);
}
