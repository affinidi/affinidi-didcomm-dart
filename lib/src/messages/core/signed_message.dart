import 'package:json_annotation/json_annotation.dart';
import '../signatures/signature.dart';
import '../didcomm_message.dart';

part 'signed_message.g.dart';

@JsonSerializable()
class SignedMessage extends DidcommMessage {
  @override
  String get mediaType => 'application/didcomm-signed+json';

  final String payload;
  final List<Signature> signatures;

  SignedMessage({required this.payload, required this.signatures});

  factory SignedMessage.fromJson(Map<String, dynamic> json) =>
      _$SignedMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SignedMessageToJson(this);
}
