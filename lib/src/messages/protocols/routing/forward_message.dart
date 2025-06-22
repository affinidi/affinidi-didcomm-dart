import '../../core.dart';

class ForwardMessage extends PlainTextMessage {
  final String next;

  ForwardMessage({
    required super.id,
    required super.to,
    required super.attachments,
    required this.next,
    super.expiresTime,
    super.from,
  }) : super(
          type: Uri.parse('https://didcomm.org/routing/2.0/forward'),
          body: {'next': next},
        );

  factory ForwardMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = PlainTextMessage.fromJson(json);
    return ForwardMessage(
      id: plainTextMessage.id,
      to: plainTextMessage.to,
      next: plainTextMessage.body?['next'],
      attachments: plainTextMessage.attachments,
    );
  }
}
