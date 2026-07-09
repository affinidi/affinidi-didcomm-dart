import 'package:didcomm/src/mediator_client/connection.dart';
import 'package:test/test.dart';

void main() {
  group('Connection.drainInboxMessages', () {
    test('emits each inbox message once, deduplicating by id across polls',
        () async {
      // The mediator keeps returning previously seen ids on later polls
      // (e.g. when messages are not deleted on the mediator).
      final inboxByAttempt = <List<String>>[
        ['1'],
        ['1', '2'],
        ['1', '2'],
      ];
      var attempt = 0;

      final fetchedIdBatches = <List<String>>[];
      final emitted = <Map<String, dynamic>>[];
      final seenMessageIds = <String>{};

      await Connection.drainInboxMessages(
        listMessageIds: () async {
          final ids = inboxByAttempt[attempt];
          attempt++;
          return ids;
        },
        fetchMessagesByIds: (ids) async {
          fetchedIdBatches.add(ids);
          return ids.map((id) => <String, dynamic>{'id': id}).toList();
        },
        emit: (message) async => emitted.add(message),
        isActive: () => true,
        seenMessageIds: seenMessageIds,
        maxAttempts: 3,
        interval: Duration.zero,
      );

      // only not-yet-seen ids are fetched on each poll
      expect(fetchedIdBatches, [
        ['1'],
        ['2'],
      ]);

      // each message is emitted exactly once despite being listed repeatedly
      expect(emitted, [
        {'id': '1'},
        {'id': '2'},
      ]);

      // every emitted message id is tracked as seen
      expect(seenMessageIds, {'1', '2'});
    });

    test('stops polling once the connection is no longer active', () async {
      var listCalls = 0;
      var active = true;
      final seenMessageIds = <String>{};

      await Connection.drainInboxMessages(
        listMessageIds: () async {
          listCalls++;
          // the connection is stopped right after the first poll
          active = false;
          return <String>[];
        },
        fetchMessagesByIds: (ids) async => [],
        emit: (message) async {},
        isActive: () => active,
        seenMessageIds: seenMessageIds,
        maxAttempts: 5,
        interval: Duration.zero,
      );

      // the second iteration should break before listing again
      expect(listCalls, 1);

      // nothing was emitted, so no ids are tracked
      expect(seenMessageIds, isEmpty);
    });

    test('does not fetch when the inbox is empty', () async {
      var fetchCalled = false;
      final seenMessageIds = <String>{};

      await Connection.drainInboxMessages(
        listMessageIds: () async => <String>[],
        fetchMessagesByIds: (ids) async {
          fetchCalled = true;
          return [];
        },
        emit: (message) async {},
        isActive: () => true,
        seenMessageIds: seenMessageIds,
        maxAttempts: 3,
        interval: Duration.zero,
      );

      expect(fetchCalled, isFalse);

      // an empty inbox tracks no ids
      expect(seenMessageIds, isEmpty);
    });

    test(
      'does not emit messages already present in the shared seenMessageIds',
      () async {
        // ids '1' and '2' were already delivered over the WebSocket
        // (live delivery) and recorded in the shared set.
        final seenMessageIds = <String>{'1', '2'};

        final fetchedIdBatches = <List<String>>[];
        final emitted = <Map<String, dynamic>>[];

        await Connection.drainInboxMessages(
          listMessageIds: () async => ['1', '2', '3'],
          fetchMessagesByIds: (ids) async {
            fetchedIdBatches.add(ids);
            return ids.map((id) => <String, dynamic>{'id': id}).toList();
          },
          emit: (message) async => emitted.add(message),
          isActive: () => true,
          seenMessageIds: seenMessageIds,
          maxAttempts: 1,
          interval: Duration.zero,
        );

        // only the id not already delivered over the socket is fetched/emitted
        expect(fetchedIdBatches, [
          ['3'],
        ]);
        expect(emitted, [
          {'id': '3'},
        ]);
      },
    );

    test('records drained ids into the shared seenMessageIds', () async {
      // the live-delivery path can later skip these ids to avoid duplicates
      final seenMessageIds = <String>{};

      await Connection.drainInboxMessages(
        listMessageIds: () async => ['1', '2'],
        fetchMessagesByIds: (ids) async =>
            ids.map((id) => <String, dynamic>{'id': id}).toList(),
        emit: (message) async {},
        isActive: () => true,
        seenMessageIds: seenMessageIds,
        maxAttempts: 1,
        interval: Duration.zero,
      );

      expect(seenMessageIds, {'1', '2'});
    });
  });
}
