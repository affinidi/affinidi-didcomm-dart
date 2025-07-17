import 'package:didcomm/didcomm.dart';
import 'package:test/test.dart';

void main() {
  group('Discover Features Messages', () {
    group('Query Message', () {
      test('toJson/fromJson roundtrip', () {
        final queryMessage = QueryMessage(
          id: 'yWd8wfYzhmuXX3hmLNaV5bVbAjbWaU',
          body: QueryBody(
            queries: [
              Query(
                featureType: FeatureType.protocol,
                match: 'https://didcomm.org/tictactoe/1.*',
              ),
              Query(
                featureType: FeatureType.goalCode,
                match: 'org.didcomm.*',
              ),
            ],
          ),
        );

        final json = queryMessage.toJson();
        final actualMessage = QueryMessage.fromJson(json);
        final actualBody = QueryBody.fromJson(actualMessage.body!);

        expect(actualMessage.id, queryMessage.id);
        expect(actualBody.queries.length, 2);
        expect(actualBody.queries[0].featureType, FeatureType.protocol);
        expect(
            actualBody.queries[0].match, 'https://didcomm.org/tictactoe/1.*');
        expect(actualBody.queries[1].featureType, FeatureType.goalCode);
        expect(actualBody.queries[1].match, 'org.didcomm.*');
      });

      test('handles unknown featureType', () {
        final json = {
          'id': 'test-unknown',
          'type': 'https://didcomm.org/discover-features/2.0/queries',
          'body': {
            'queries': [
              {'feature-type': 'not-a-real-type', 'match': 'foo'}
            ]
          }
        };
        final actualMessage = QueryMessage.fromJson(json);
        final actualBody = QueryBody.fromJson(actualMessage.body!);
        expect(actualBody.queries.length, 1);
        expect(actualBody.queries[0].featureType, FeatureType.unknown);
        expect(actualBody.queries[0].match, 'foo');
      });
    });
  });

  group('Disclose Message', () {
    test('DiscloseMessage toJson/fromJson roundtrip', () {
      final discloseMessage = DiscloseMessage(
        id: 'a8Fj3kLzQw9Xv2R6sT1bN4yP0eHcVmZq',
        parentThreadId: 'yWd8wfYzhmuXX3hmLNaV5bVbAjbWaU',
        body: DiscloseBody(
          disclosures: [
            Disclosure(
              featureType: FeatureType.protocol,
              id: 'https://didcomm.org/tictactoe/1.0',
              roles: ['player'],
            ),
            Disclosure(
              featureType: FeatureType.goalCode,
              id: 'org.didcomm.sell.goods.consumer',
              roles: null,
            ),
          ],
        ),
      );

      final json = discloseMessage.toJson();

      final actualMessage = DiscloseMessage.fromJson(json);
      final actualBody = DiscloseBody.fromJson(actualMessage.body!);

      expect(actualMessage.type.toString(), discloseMessage.type.toString());
      expect(actualMessage.parentThreadId, discloseMessage.parentThreadId);
      expect(actualBody.disclosures.length, 2);
      expect(actualBody.disclosures[0].featureType, FeatureType.protocol);
      expect(actualBody.disclosures[0].id, 'https://didcomm.org/tictactoe/1.0');
      expect(actualBody.disclosures[0].roles, ['player']);
      expect(actualBody.disclosures[1].featureType, FeatureType.goalCode);
      expect(actualBody.disclosures[1].id, 'org.didcomm.sell.goods.consumer');
      expect(actualBody.disclosures[1].roles, isNull);
    });

    test('handles unknown featureType', () {
      final json = {
        'id': 'test-unknown',
        'type': 'https://didcomm.org/discover-features/2.0/disclose',
        'body': {
          'disclosures': [
            {'feature-type': 'not-a-real-type', 'id': 'foo'}
          ]
        }
      };
      final actualMessage = DiscloseMessage.fromJson(json);
      final actualBody = DiscloseBody.fromJson(actualMessage.body!);

      expect(actualBody.disclosures.length, 1);
      expect(actualBody.disclosures[0].featureType, FeatureType.unknown);
      expect(actualBody.disclosures[0].id, 'foo');
    });
  });
}
