import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import 'helpers.dart';

void main() async {
  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);

  final aliceDidManager = DidKeyManager(
    wallet: aliceWallet,
    store: InMemoryDidStore(),
  );

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);

  final bobDidManager = DidKeyManager(
    wallet: bobWallet,
    store: InMemoryDidStore(),
  );

  final aliceKeyId = 'alice-key-1';
  await aliceWallet.generateKey(
    keyId: aliceKeyId,
    keyType: KeyType.p256,
  );

  await aliceDidManager.addVerificationMethod(aliceKeyId);
  final aliceDidDocument = await aliceDidManager.getDidDocument();

  final aliceSigner = await aliceDidManager.getSigner(
    aliceDidDocument.assertionMethod.first.id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final bobKeyId = 'bob-key-1';
  await bobWallet.generateKey(
    keyId: bobKeyId,
    keyType: KeyType.p256,
  );

  await bobDidManager.addVerificationMethod(bobKeyId);
  final bobDidDocument = await bobDidManager.getDidDocument();

  final alicePlainTextMassage = PlainTextMessage(
    id: '041b47d4-9c8f-4a24-ae85-b60ec91b025c',
    from: aliceDidDocument.id,
    to: [bobDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': 'Hello, Bob!'},
  );

  alicePlainTextMassage['custom-header'] = 'custom-value';

  prettyPrint(
    'Plain Text Message for Bob',
    object: alicePlainTextMassage,
  );

  final aliceSignedMessage = await SignedMessage.pack(
    alicePlainTextMassage,
    signer: aliceSigner,
  );

  prettyPrint(
    'Signed Message by Alice',
    object: aliceSignedMessage,
  );

  // find keys whose curve is common in other DID Documents
  final aliceMatchedKeyIds = aliceDidDocument.matchKeysInKeyAgreement(
    otherDidDocuments: [bobDidDocument],
  );

  final aliceEncryptedMessage = await EncryptedMessage.packWithAuthentication(
    aliceSignedMessage,
    keyPair: await aliceDidManager.getKeyPairByDidKeyId(
      aliceMatchedKeyIds.first,
    ),
    didKeyId: aliceMatchedKeyIds.first,
    recipientDidDocuments: [bobDidDocument],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  prettyPrint(
    'Encrypted Message by Alice',
    object: aliceEncryptedMessage,
  );

  final sentMessageByAlice = jsonEncode(aliceEncryptedMessage);

  final unpackedMessageByBob = await DidcommMessage.unpackToPlainTextMessage(
    message: jsonDecode(sentMessageByAlice) as Map<String, dynamic>,
    recipientDidManager: bobDidManager,
    expectedMessageWrappingTypes: [
      MessageWrappingType.authcryptSignPlaintext,
    ],
    expectedSigners: [
      aliceDidDocument.assertionMethod.first.didKeyId,
    ],
  );

  prettyPrint(
    'Unpacked Plain Text Message received by Bob',
    object: unpackedMessageByBob,
  );
}
