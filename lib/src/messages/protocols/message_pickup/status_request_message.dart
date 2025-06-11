import '../../core.dart';

class StatusRequestMessage extends PlainTextMessage {
  final String recipientDid;

  StatusRequestMessage({
    required super.id,
    required super.to,
    required this.recipientDid,
    required super.from,
    super.expiresTime,
  }) : super(
          type: Uri.parse(
            'https://didcomm.org/messagepickup/3.0/status-request',
          ),
          body: {'recipient_did': recipientDid},
        ) {
    this['return_route'] = 'all';
  }

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
