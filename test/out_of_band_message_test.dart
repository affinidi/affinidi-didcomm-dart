import 'package:didcomm/didcomm.dart';
import 'package:test/test.dart';

void main() {
  group('OutOfBandMessage', () {
    const id = '123';
    const from = 'did:example:alice';
    const goal = 'To connect';
    const goalCode = 'connect';
    final body = {'content': 'Hello, Bob!', goal: goal, goalCode: goalCode};

    test('toURL returns valid URL for simple message', () {
      final msg = OutOfBandMessage(
        id: id,
        from: from,
        body: body,
      );
      final origin = 'https://example.com';
      final url = msg.toURL(origin: origin);
      expect(url.toString(), startsWith(origin));
      expect(url.queryParameters['oob'], isNotNull);
      expect(url.queryParameters['oob'], isNotEmpty);
    });

    test('toURL throws on empty origin', () {
      final msg = OutOfBandMessage(
        id: id,
        from: from,
        body: body,
      );
      expect(() => msg.toURL(origin: ''), throwsArgumentError);
    });

    test('toURL throws on invalid origin', () {
      final msg = OutOfBandMessage(
        id: id,
        from: from,
        body: body,
      );
      expect(() => msg.toURL(origin: 'not a url'), throwsArgumentError);
    });

    test('toURL throws if URL exceeds 2048 chars', () {
      final msg = OutOfBandMessage(
        id: id,
        from: from,
        body: {'content': 'Hello, Bob!' * 3000},
      );
      expect(() => msg.toURL(origin: 'https://example.com'),
          throwsFormatException);
    });

    test('it return original message from url', () {
      final msg = OutOfBandMessage(
        id: id,
        from: from,
        body: body,
      );
      final origin = 'https://example.com';
      final url = msg.toURL(origin: origin);
      final parsedMsg = OutOfBandMessage.fromURL(url.toString());
      expect(parsedMsg.id, equals(msg.id));
      expect(parsedMsg.from, equals(msg.from));
      expect(parsedMsg.body, equals(msg.body));
    });
  });
}
