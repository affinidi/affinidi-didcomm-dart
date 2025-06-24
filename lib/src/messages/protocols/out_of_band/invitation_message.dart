import 'package:json_annotation/json_annotation.dart';
import '../../didcomm_message.dart';

part 'invitation_message.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class InvitationMessage extends DidcommMessage {
  InvitationMessage();

  factory InvitationMessage.fromJson(Map<String, dynamic> json) =>
      _$InvitationMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$InvitationMessageToJson(this);
}
