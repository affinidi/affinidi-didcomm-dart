import 'package:didcomm/didcomm.dart';
import 'package:test/test.dart';

void main() {
  group('ProblemReportMessage', () {
    test('serializes and deserializes correctly', () {
      final originalMessage = ProblemReportMessage(
        id: '123',
        parentThreadId: 'thread-1',
        acknowledged: ['122'],
        body: ProblemReportBody(
          code: ProblemCode(
            sorter: SorterType.error,
            scope: Scope(scope: ScopeType.protocol),
            descriptors: [DescriptorType.xfer.code, 'cant-use-endpoint'],
          ),
          comment: 'Unable to use the endpoint.',
          arguments: ['arg1', 'arg2'],
          escalateTo: 'mailto:admin@foo.org',
        ),
      );

      final json = originalMessage.toJson();
      final deserialized = ProblemReportMessage.fromJson(json);

      expect(deserialized.id, originalMessage.id);
      expect(deserialized.parentThreadId, originalMessage.parentThreadId);
      expect(deserialized.acknowledged, originalMessage.acknowledged);

      // Reconstruct ProblemReportBody from deserialized.body
      final body =
          ProblemReportBody.fromJson(deserialized.body as Map<String, dynamic>);

      expect(body.code.sorter, SorterType.error);
      expect(body.code.scope.scope, ScopeType.protocol);
      expect(body.code.descriptors, ['xfer', 'cant-use-endpoint']);
      expect(body.comment, 'Unable to use the endpoint.');
      expect(body.arguments, ['arg1', 'arg2']);
      expect(body.escalateTo, 'mailto:admin@foo.org');
    });
  });
}
