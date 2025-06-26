import 'package:didcomm/didcomm.dart';

class MessageAssertionService {
  static PlainTextMessage createPlainTextMessageAssertion(
    String message, {
    required String from,
    required List<String> to,
  }) {
    final plainTextMessage = PlainTextMessage(
      id: 'test-id',
      from: from,
      to: to,
      type: Uri.parse('https://didcomm.org/example/1.0/message'),
      body: {'content': message},
    );

    return plainTextMessage;
  }
}
