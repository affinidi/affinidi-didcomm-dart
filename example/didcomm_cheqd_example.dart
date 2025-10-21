import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

void main() async {
  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);

  final aliceDidManager = DidCheqdManager(
    wallet: aliceWallet,
    store: InMemoryDidStore(),
  );

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);

  final bobDidManager = DidKeyManager(
    wallet: bobWallet,
    store: InMemoryDidStore(),
  );

  // Create Ed25519 key for Alice (required for Cheqd)
  final aliceEd25519KeyId = 'alice-ed25519-key';
  final aliceEd25519KeyPair = await aliceWallet.generateKey(
    keyId: aliceEd25519KeyId,
    keyType: KeyType.ed25519, // Cheqd requires Ed25519 keys
  );

  // Create P256 key for Alice
  final aliceP256KeyId = 'alice-p256-key';
  final aliceP256KeyPair = await aliceWallet.generateKey(
    keyId: aliceP256KeyId,
    keyType: KeyType.p256,
  );

  // Add Ed25519 key for authentication
  await aliceDidManager.addVerificationMethod(
    aliceEd25519KeyPair.id,
    relationships: {VerificationRelationship.authentication},
  );

  // Add P256 key for key agreement
  await aliceDidManager.addVerificationMethod(
    aliceP256KeyPair.id,
    relationships: {
      VerificationRelationship.keyAgreement,
      VerificationRelationship.authentication,
    },
  );

  await aliceDidManager.registerDid(
    [aliceEd25519KeyPair.id, aliceP256KeyPair.id],
    network: 'testnet', // or 'mainnet'
    registrarUrl: 'http://localhost:3000',
  );
  final aliceDidDocument = await aliceDidManager.getDidDocument();

  final aliceSigner = await aliceDidManager.getSigner(
    aliceDidDocument.assertionMethod.first.id,
  );

  // Create P256 key for Bob (DidKeyManager doesn't support multiple keys)
  final bobP256KeyId = 'bob-p256-key';
  await bobWallet.generateKey(
    keyId: bobP256KeyId,
    keyType: KeyType.p256,
  );

  // Add P256 key (DidKeyManager doesn't support relationships parameter)
  await bobDidManager.addVerificationMethod(bobP256KeyId);
  
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
  // final aliceMatchedKeyIds = aliceDidDocument.matchKeysInKeyAgreement(
  //   otherDidDocuments: [bobDidDocument],
  // );

  // Find Alice's P256 key for key agreement (use the second one, which should be P256)
  final aliceP256VerificationMethod = aliceDidDocument.verificationMethod[1];
  
  final aliceEncryptedMessage = await EncryptedMessage.packWithAuthentication(
    aliceSignedMessage,
    keyPair: await aliceDidManager.getKeyPairByDidKeyId(
      aliceP256VerificationMethod.didKeyId,
    ),
    didKeyId: aliceP256VerificationMethod.didKeyId,
    recipientDidDocuments: [bobDidDocument],
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
