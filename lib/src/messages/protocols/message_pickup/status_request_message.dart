import '../../core.dart';
import 'message_pickup_message/message_pickup_message.dart';

class StatusRequestMessage extends MessagePickupMessage {
  final String recipientDid;

  StatusRequestMessage({
    required super.id,
    required super.to,
    required this.recipientDid,
    required super.from,
    super.expiresTime,
    super.returnRoute,
  }) : super(
          type: Uri.parse(
            'https://didcomm.org/messagepickup/3.0/status-request',
          ),
          body: {'recipient_did': recipientDid},
        );

  factory StatusRequestMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = PlainTextMessage.fromJson(json);
    return StatusRequestMessage(
      id: plainTextMessage.id,
      to: plainTextMessage.to,
      recipientDid: plainTextMessage.body?['recipient_did'],
      from: plainTextMessage.from,
    );
  }
}
