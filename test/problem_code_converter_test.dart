import 'package:didcomm/didcomm.dart';
import 'package:test/test.dart';

void main() {
  group('ProblemCodeConverter', () {
    const converter = ProblemCodeConverter();

    group('fromJson', () {
      test('parses sorter, scope, and descriptors', () {
        final code = 'e.p.xfer.cant-use-endpoint';
        final actual = converter.fromJson(code);

        expect(actual.sorter, SorterType.error);
        expect(actual.scope.scope, ScopeType.protocol);
        expect(actual.descriptors, [
          DescriptorType.xfer.code,
          'cant-use-endpoint',
        ]);
      });

      test('handles scope as state name', () {
        final code = 'e.get-pay-details.payment-failed';
        final actual = converter.fromJson(code);

        expect(actual.sorter, SorterType.error);
        expect(actual.scope.stateName, 'get-pay-details');
        expect(actual.descriptors, ['payment-failed']);
      });

      test('handles unknown sorter and scope', () {
        final code = '..unknown1.unknown2';
        final actual = converter.fromJson(code);

        expect(actual.sorter, SorterType.unrecognized);
        expect(actual.scope.scope, ScopeType.unrecognized);
        expect(actual.descriptors, ['unknown1', 'unknown2']);
      });
    });

    group('toJson', () {
      test('serializes to string', () {
        final problem = ProblemCode(
          sorter: SorterType.error,
          scope: Scope(scope: ScopeType.protocol),
          descriptors: [DescriptorType.xfer.code, 'cant-use-endpoint'],
        );

        final actual = converter.toJson(problem);
        expect(actual, 'e.p.xfer.cant-use-endpoint');
      });
    });
  });
}
