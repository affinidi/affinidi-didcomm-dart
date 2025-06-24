import 'package:didcomm/didcomm.dart';
import 'package:test/test.dart';

void main() {
  group('OutOfBandMessage', () {
    const id = '123';
    const from = 'did:example:alice';
    const goal = 'To connect';
    const goalCode = 'connect';
    final body = {'foo': 'bar'};

    test('toURL returns valid URL for simple message', () {
      final msg = OutOfBandMessage(
        id: id,
        from: from,
        goal: goal,
        goalCode: goalCode,
        body: body,
      );
      final origin = 'https://example.com';
      final url = msg.toURL(origin: origin);
      expect(url.startsWith(origin), isTrue);
      expect(url.contains('oob='), isTrue);
      expect(url.length <= 2048, isTrue);
    });

    test('toURL throws on empty origin', () {
      final msg = OutOfBandMessage(
        id: id,
        from: from,
        goal: goal,
        goalCode: goalCode,
        body: body,
      );
      expect(() => msg.toURL(origin: ''), throwsArgumentError);
    });

    test('toURL throws on invalid origin', () {
      final msg = OutOfBandMessage(
        id: id,
        from: from,
        goal: goal,
        goalCode: goalCode,
        body: body,
      );
      expect(() => msg.toURL(origin: 'not a url'), throwsArgumentError);
    });

    test('toURL throws if URL exceeds 2048 chars', () {
      final msg = OutOfBandMessage(
        id: id,
        from: from,
        goal: goal,
        goalCode: goalCode,
        body: {'a': 'x' * 3000},
      );
      expect(() => msg.toURL(origin: 'https://example.com'),
          throwsFormatException);
    });
  });
}
