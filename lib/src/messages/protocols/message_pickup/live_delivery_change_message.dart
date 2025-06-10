import '../../core.dart';

class LiveDeliveryChangeMessage extends PlainTextMessage {
  final bool liveDelivery;

  LiveDeliveryChangeMessage({
    required super.id,
    required super.to,
    required this.liveDelivery,
    required super.from,
    super.expiresTime,
  }) : super(
          type: Uri.parse(
            'https://didcomm.org/messagepickup/3.0/live-delivery-change',
          ),
          body: {'live_delivery': liveDelivery},
        );

  factory LiveDeliveryChangeMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = PlainTextMessage.fromJson(json);
    return LiveDeliveryChangeMessage(
      id: plainTextMessage.id,
      to: plainTextMessage.to,
      liveDelivery: plainTextMessage.body?['live_delivery'],
      from: plainTextMessage.from,
    );
  }
}
