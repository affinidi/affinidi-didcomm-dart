import 'package:json_annotation/json_annotation.dart';
import '../didcomm_message.dart';

part 'plaintext_message.g.dart';

@JsonSerializable()
class PlaintextMessage extends DidcommMessage {
  PlaintextMessage();

  factory PlaintextMessage.fromJson(Map<String, dynamic> json) =>
      _$PlaintextMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PlaintextMessageToJson(this);
}
