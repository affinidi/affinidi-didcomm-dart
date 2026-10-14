import 'package:didcomm/didcomm.dart';
import 'package:test/test.dart';

void main() {
  const issuer = 'did:example:alice';
  const recipient = 'did:example:mediator';
  final taskType = Uri.parse(
    'https://trusttasks.org/spec/messaging/access-list/update/0.1',
  );
  final payload = {
    'did': 'hash',
    'add': ['other-hash'],
  };

  group('TrustTaskDocument', () {
    test('serializes all fields', () {
      final issuedAt = DateTime.utc(2026, 10, 9, 10, 0, 0);
      final document = TrustTaskDocument(
        id: 'urn:uuid:123',
        type: taskType,
        issuer: issuer,
        recipient: recipient,
        issuedAt: issuedAt,
        payload: payload,
      );

      expect(document.toJson(), {
        'id': 'urn:uuid:123',
        'type': taskType.toString(),
        'issuer': issuer,
        'recipient': recipient,
        'issuedAt': '2026-10-09T10:00:00.000Z',
        'payload': payload,
      });
    });

    test('defaults to a unique urn:uuid id', () {
      TrustTaskDocument create() => TrustTaskDocument(
            type: taskType,
            issuer: issuer,
            recipient: recipient,
            payload: payload,
          );

      final first = create();
      final second = create();

      expect(first.id, startsWith('urn:uuid:'));
      expect(first.id, isNot(second.id));
    });

    test('stores issuedAt in UTC and defaults to now', () {
      final before = DateTime.now().toUtc();
      final document = TrustTaskDocument(
        type: taskType,
        issuer: issuer,
        recipient: recipient,
        payload: payload,
      );

      expect(document.issuedAt.isUtc, isTrue);
      expect(document.issuedAt.isBefore(before), isFalse);
      expect(document.toJson()['issuedAt'], endsWith('Z'));
    });

    test('converts a local issuedAt to UTC', () {
      final local = DateTime(2026, 10, 9, 12);
      final document = TrustTaskDocument(
        type: taskType,
        issuer: issuer,
        recipient: recipient,
        issuedAt: local,
        payload: payload,
      );

      expect(document.issuedAt, local.toUtc());
      expect(document.issuedAt.isUtc, isTrue);
    });

    test('round-trips through JSON', () {
      final document = TrustTaskDocument(
        id: 'urn:uuid:123',
        type: taskType,
        issuer: issuer,
        recipient: recipient,
        issuedAt: DateTime.utc(2026, 10, 9, 10, 0, 0),
        payload: payload,
      );

      final parsed = TrustTaskDocument.fromJson(document.toJson());

      expect(parsed.toJson(), document.toJson());
    });

    test('keeps the threadId and proof of a response', () {
      final json = {
        'id': 'response-1',
        'type': '$taskType#response',
        'issuer': recipient,
        'recipient': issuer,
        'issuedAt': '2026-10-09T10:00:01.000Z',
        'payload': {'ok': true},
        'threadId': 'urn:uuid:123',
        'proof': {'type': 'DataIntegrityProof', 'proofValue': 'z123'},
      };

      final document = TrustTaskDocument.fromJson(json);

      expect(document.threadId, 'urn:uuid:123');
      expect(document.proof, json['proof']);
      expect(document.toJson(), json);
    });

    group('fromJson rejects', () {
      final valid = TrustTaskDocument(
        type: taskType,
        issuer: issuer,
        recipient: recipient,
        payload: payload,
      ).toJson();

      final cases = <String, Map<String, dynamic>>{
        'a missing field': {...valid}..remove('issuer'),
        'a wrongly typed field': {...valid, 'payload': 'not a map'},
        'a wrongly typed optional field': {...valid, 'threadId': 42},
        'a malformed issuedAt': {...valid, 'issuedAt': 'yesterday'},
      };

      cases.forEach((name, json) {
        test(name, () {
          expect(
            () => TrustTaskDocument.fromJson(json),
            throwsFormatException,
          );
        });
      });
    });
  });

  group('TrustTaskMessage', () {
    final document = TrustTaskDocument(
      type: taskType,
      issuer: issuer,
      recipient: recipient,
      payload: payload,
    );

    test('wraps the document in the DIDComm envelope', () {
      final message = TrustTaskMessage(id: 'msg-1', document: document);

      expect(
        message.type.toString(),
        'https://trusttasks.org/binding/didcomm/0.1/envelope',
      );
      expect(message.body, document.toJson());
    });

    test('takes addressing from the document', () {
      final message = TrustTaskMessage(id: 'msg-1', document: document);

      expect(message.from, issuer);
      expect(message.to, [recipient]);
    });

    test('isTrustTask recognises envelope messages only', () {
      final trustTask = TrustTaskMessage(id: 'msg-1', document: document);
      final other = PlainTextMessage(
        id: 'msg-2',
        type: Uri.parse('https://didcomm.org/trust-ping/2.0/ping'),
      );

      expect(TrustTaskMessage.isTrustTask(trustTask), isTrue);
      expect(
        TrustTaskMessage.isTrustTask(
          PlainTextMessage.fromJson(trustTask.toJson()),
        ),
        isTrue,
      );
      expect(TrustTaskMessage.isTrustTask(other), isFalse);
    });

    test('parses a message from JSON', () {
      final message = TrustTaskMessage(
        id: 'msg-1',
        document: document,
        threadId: 'thread-1',
      );

      final parsed = TrustTaskMessage.fromJson(message.toJson());

      expect(parsed.id, 'msg-1');
      expect(parsed.threadId, 'thread-1');
      expect(parsed.from, issuer);
      expect(parsed.to, [recipient]);
      expect(parsed.document.toJson(), document.toJson());
    });

    test('fromJson rejects other message types', () {
      final other = PlainTextMessage(
        id: 'msg-2',
        type: Uri.parse('https://didcomm.org/trust-ping/2.0/ping'),
        from: issuer,
        body: document.toJson(),
      );

      expect(
        () => TrustTaskMessage.fromJson(other.toJson()),
        throwsFormatException,
      );
    });

    test('fromJson rejects a sender that is not the issuer', () {
      final json = TrustTaskMessage(id: 'msg-1', document: document).toJson()
        ..['from'] = 'did:example:mallory';

      expect(() => TrustTaskMessage.fromJson(json), throwsFormatException);
    });

    test('fromJson keeps acknowledgements and attachments', () {
      final message = TrustTaskMessage(
        id: 'msg-1',
        document: document,
        pleaseAcknowledge: ['msg-0'],
        acknowledged: ['msg-00'],
        attachments: [
          Attachment(id: 'att-1', data: AttachmentData(json: '{}')),
        ],
      );

      final parsed = TrustTaskMessage.fromJson(message.toJson());

      expect(parsed.pleaseAcknowledge, ['msg-0']);
      expect(parsed.acknowledged, ['msg-00']);
      expect(parsed.attachments?.single.id, 'att-1');
      expect(parsed.toJson(), message.toJson());
    });

    group('fromJson rejects recipients other than the document recipient', () {
      final cases = <String, List<String>?>{
        'none': null,
        'another DID': ['did:example:mallory'],
        'an additional DID': [recipient, 'did:example:mallory'],
      };

      cases.forEach((name, to) {
        test(name, () {
          final json =
              TrustTaskMessage(id: 'msg-1', document: document).toJson();
          if (to == null) {
            json.remove('to');
          } else {
            json['to'] = to;
          }

          expect(() => TrustTaskMessage.fromJson(json), throwsFormatException);
        });
      });
    });

    test('fromJson rejects a message without a body', () {
      final json = TrustTaskMessage(id: 'msg-1', document: document).toJson()
        ..remove('body');

      expect(() => TrustTaskMessage.fromJson(json), throwsFormatException);
    });

    test('fromJson rejects a malformed document', () {
      final json = TrustTaskMessage(id: 'msg-1', document: document).toJson()
        ..['body'] = {'id': 'urn:uuid:123'};

      expect(() => TrustTaskMessage.fromJson(json), throwsFormatException);
    });
  });
}
