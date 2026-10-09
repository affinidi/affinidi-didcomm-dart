import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/messages/protocols/trust_task/mediator/did_hash.dart';
import 'package:test/test.dart';

void main() {
  const alice = 'did:example:alice';
  const bob = 'did:example:bob';
  const carol = 'did:example:carol';
  const mediator = 'did:example:mediator';

  group('AccessListUpdateTask', () {
    test('addresses the mediator and targets the issuer by default', () {
      final task = AccessListUpdateTask(
        issuer: alice,
        mediatorDid: mediator,
        add: [bob],
      );

      expect(
        task.type.toString(),
        'https://trusttasks.org/spec/messaging/access-list/update/0.1',
      );
      expect(task.issuer, alice);
      expect(task.recipient, mediator);
      expect(task.payload, {
        'did': mediatorDidHash(alice),
        'add': [mediatorDidHash(bob)],
      });
    });

    test('hashes removed DIDs and targets an explicit DID', () {
      final task = AccessListUpdateTask(
        issuer: alice,
        mediatorDid: mediator,
        targetDid: carol,
        remove: [bob],
      );

      expect(task.payload, {
        'did': mediatorDidHash(carol),
        'remove': [mediatorDidHash(bob)],
      });
    });

    test('includes clear, add and remove together', () {
      final task = AccessListUpdateTask(
        issuer: alice,
        mediatorDid: mediator,
        clear: true,
        add: [bob],
        remove: [carol],
      );

      expect(task.payload, {
        'did': mediatorDidHash(alice),
        'clear': true,
        'add': [mediatorDidHash(bob)],
        'remove': [mediatorDidHash(carol)],
      });
    });

    test('throws if nothing would change', () {
      expect(
        () => AccessListUpdateTask(issuer: alice, mediatorDid: mediator),
        throwsArgumentError,
      );
    });
  });

  group('AccountUpdateTask', () {
    test('sends only the set ACL flags', () {
      final task = AccountUpdateTask(
        issuer: alice,
        mediatorDid: mediator,
        acl: const MediatorAcl(accessListMode: AccessListMode.explicitDeny),
      );

      expect(
        task.type.toString(),
        'https://trusttasks.org/spec/messaging/account/update/0.1',
      );
      expect(task.recipient, mediator);
      expect(task.payload, {
        'did': mediatorDidHash(alice),
        'acl': {'accessListMode': 'explicitDeny'},
      });
    });

    test('targets an explicit DID', () {
      final task = AccountUpdateTask(
        issuer: alice,
        mediatorDid: mediator,
        targetDid: bob,
        acl: const MediatorAcl(createInvites: false),
      );

      expect(task.payload['did'], mediatorDidHash(bob));
    });

    test('throws if no ACL flag is set', () {
      expect(
        () => AccountUpdateTask(
          issuer: alice,
          mediatorDid: mediator,
          acl: const MediatorAcl(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('MediatorAcl', () {
    test('serializes every flag with its wire name', () {
      const acl = MediatorAcl(
        accessListMode: AccessListMode.explicitAllow,
        blocked: false,
        local: true,
        sendMessages: true,
        receiveMessages: true,
        sendForwarded: false,
        receiveForwarded: false,
        createInvites: true,
        anonReceive: false,
        selfManageList: true,
        selfManageSendQueueLimit: false,
        selfManageReceiveQueueLimit: false,
      );

      expect(acl.toJson(), {
        'accessListMode': 'explicitAllow',
        'blocked': false,
        'local': true,
        'sendMessages': true,
        'receiveMessages': true,
        'sendForwarded': false,
        'receiveForwarded': false,
        'createInvites': true,
        'anonReceive': false,
        'selfManageList': true,
        'selfManageSendQueueLimit': false,
        'selfManageReceiveQueueLimit': false,
      });
    });

    test('omits unset flags', () {
      expect(const MediatorAcl().toJson(), isEmpty);
    });
  });
}
