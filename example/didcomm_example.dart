import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/encryption_algorithm.dart';
import 'package:didcomm/src/messages/didcomm_message.dart';
import 'package:ssi/ssi.dart';
import 'package:ssi/src/wallet/key_store/in_memory_key_store.dart';

void main() async {
  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);

  final aliceKeyId = 'alice-key-1';
  final aliceKeyPair = await aliceWallet.generateKey(
    keyId: aliceKeyId,
    keyType: KeyType.p256,
  );

  final aliceDidDocument = DidKey.generateDocument(aliceKeyPair.publicKey);

  final bobKeyId = 'bob-key-1';
  final bobKeyPair = await bobWallet.generateKey(
    keyId: bobKeyId,
    keyType: KeyType.p256,
  );

  final bobDidDocument = DidKey.generateDocument(bobKeyPair.publicKey);

  // TODO: kid is not available in the Jwk anymore. clarify with the team
  final bobJwk = bobDidDocument.keyAgreement[0].asJwk().toJson();
  bobJwk['kid'] = '${bobDidDocument.id}#$bobKeyId';

  final plainMessage = PlaintextMessage.fromJson({
    'id': '041b47d4-9c8f-4a24-ae85-b60ec91b025c',
    'from': aliceDidDocument.id,
    'type': 'https://didcomm.org/example/1.0/message',
    'custom-header': 'custom-value',
  });

  print(plainMessage.toJson());
  print('');

  final encryptedMessageByAlice = await EncryptedMessage.packWithAuthentication(
    plainMessage,
    wallet: aliceWallet,
    keyId: aliceKeyId,
    jwksPerRecipient: [
      Jwks.fromJson({
        'keys': [bobJwk],
      }),
    ],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  final sentMessageByAlice = jsonEncode(encryptedMessageByAlice);
  print(sentMessageByAlice);
  print('');

  final unpackedMessageByBod = await DidcommMessage.unpackPlainTextMessage(
    message: jsonDecode(sentMessageByAlice),
    wallet: bobWallet,
  );

  print(unpackedMessageByBod.toJson());
  print('');

  /*
  // --------------------------------------------------------------------
  // Alice creates a message from Bob. The message is signed and encrypted
  // --------------------------------------------------------------------

  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);

  // final aliceKeyPair = await aliceWallet.generateKey();
  final bobKeyPair = await bobWallet.generateKey();

  // final aliceDidDoc = DidKey.generateDocument(aliceKeyPair.publicKey);
  final bobDidDoc = DidKey.generateDocument(bobKeyPair.publicKey);

  // final aliceSigner = DidSigner(
  //   didDocument: aliceDidDoc,
  //   keyPair: aliceKeyPair,
  //   didKeyId: aliceDidDoc.verificationMethod[0].id,
  //   signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  // );

  final plainTextMessage = PlaintextMessage(
    id: '123',
    from: 'did:example:123',
    to: ['did:example:456'],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    threadId: 'thread-123',
    parentThreadId: 'parent-thread-123',
    createdTime: DateTime.now(),
    expiresTime: DateTime.now().add(Duration(days: 1)),
    body: {'key': 'value'},
    attachments: [
      Attachment(
        id: 'attachment-1',
        data: AttachmentData(base64: 'base64data'),
      ),
    ],
  );

  plainTextMessage['custom-header'] = 'custom-value';

  final signedMessage = SignedMessage.fromPlainTextMessage(
    plainTextMessage,
    wallet: aliceWallet,
    walletKeyId: 'key-1',
  );

  final encryptedMessage = EncryptedMessage.fromMessage(
    signedMessage,
    wallet: bobWallet,
    walletKeyId: 'key-2',
    recipientPublicKeyJwks: [bobDidDoc.keyAgreement[0].asJwk()],
  );

  // final wrappedByMediatorMessage = ForwardMessage.fromMessage(encryptedMessage);

  // --------------------------------------------------------------------
  // Bob decrypts message and verifies signature
  // --------------------------------------------------------------------

  final extractedPlainTextMessage = DidcommMessage.extractPlainTextMessage(
    message: encryptedMessage,
    wallet: bobWallet,
  );

  final extractedSignedMessage = DidcommMessage.extractSignedMessage(
    message: encryptedMessage,
    wallet: bobWallet,
  );
  */
}
