// The legacy acl-management API stays covered until it is removed.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/messages/protocols/trust_task/mediator/did_hash.dart';
import 'package:test/test.dart';

void main() {
  const alice = 'did:example:alice';
  const bob = 'did:example:bob';
  const carol = 'did:example:carol';
  const mediator = 'did:example:mediator';

  group('AccessListAddMessage', () {
    test('adds hashed DIDs to the sender access list', () {
      final message = AccessListAddMessage(
        id: 'message-id',
        from: alice,
        to: [mediator],
        theirDids: [bob, carol],
      );

      expect(
        message.type.toString(),
        'https://didcomm.org/mediator/1.0/acl-management',
      );
      expect(message.from, alice);
      expect(message.to, [mediator]);
      expect(message.body, {
        'access_list_add': {
          'did_hash': mediatorDidHash(alice),
          'hashes': [mediatorDidHash(bob), mediatorDidHash(carol)],
        },
      });
    });
  });
}
