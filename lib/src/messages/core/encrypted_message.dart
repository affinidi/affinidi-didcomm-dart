import 'package:json_annotation/json_annotation.dart';
import '../didcomm_message.dart';

part 'encrypted_message.g.dart';

@JsonSerializable()
class EncryptedMessage extends DidcommMessage {
  EncryptedMessage();

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) =>
      _$EncryptedMessageFromJson(json);

  Map<String, dynamic> toJson() => _$EncryptedMessageToJson(this);
}
