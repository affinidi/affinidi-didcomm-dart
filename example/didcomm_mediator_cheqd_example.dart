import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../test/example_configs.dart';

void main() async {
  // Run commands below in your terminal to generate keys for Alice and Bob:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/alice_private_key.pem
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance https://github.com/affinidi/affinidi-tdk-rs/tree/main/crates/affinidi-messaging/affinidi-messaging-mediator or with https://portal.affinidi.com.
  // Copy its DID Document URL into example/mediator/mediator_did.txt.

  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);

  final aliceDidManager = DidCheqdManager(
    wallet: aliceWallet,
    store: InMemoryDidStore(),
  );

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

  // Create P256 key for Alice using persistent PEM file
  final aliceP256KeyId = 'alice-p256-key';
  final alicePrivateKeyBytes = await extractPrivateKeyBytes(
    alicePrivateKeyPath,
  );

  await aliceKeyStore.set(
    aliceP256KeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: alicePrivateKeyBytes,
    ),
  );

  // Add Ed25519 key for authentication and assertion method
  await aliceDidManager.addVerificationMethod(
    aliceEd25519KeyPair.id,
    relationships: {
      VerificationRelationship.authentication,
      VerificationRelationship.assertionMethod,
    },
  );

  // Add P256 key for key agreement
  await aliceDidManager.addVerificationMethod(
    aliceP256KeyId,
    relationships: {
      VerificationRelationship.keyAgreement,
    },
  );

  await aliceDidManager.registerDid(
    [aliceEd25519KeyPair.id, aliceP256KeyId],
    network: 'testnet', // or 'mainnet'
  );
  final aliceDidDocument = await aliceDidManager.getDidDocument();
  prettyPrint('Alice DID Document', object: aliceDidDocument);

  prettyPrint(
    'Alice DID',
    object: aliceDidDocument.id,
  );

  prettyPrint(
    'Alice DID Document',
    object: aliceDidDocument,
  );

  // Find Alice's Ed25519 key for signing (it's the first verification method)
  final aliceEd25519VerificationMethod = aliceDidDocument.verificationMethod[0];

  // Use Ed25519 key for signing (now with Ed25519 curve support)
  final aliceSigner = await aliceDidManager.getSigner(
    aliceEd25519VerificationMethod.didKeyId,
  );

  // Create P256 key for Bob using persistent PEM file
  final bobP256KeyId = 'bob-p256-key';
  final bobPrivateKeyBytes = await extractPrivateKeyBytes(
    bobPrivateKeyPath,
  );

  await bobKeyStore.set(
    bobP256KeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: bobPrivateKeyBytes,
    ),
  );

  // Add P256 key (DidKeyManager doesn't support relationships parameter)
  await bobDidManager.addVerificationMethod(bobP256KeyId);
  
  final bobDidDocument = await bobDidManager.getDidDocument();

  prettyPrint(
    'Bob DID Document',
    object: bobDidDocument,
  );

  final bobMediatorDocument = await readDidDocument(
    './example/mediator/mediator_did_document_example.json',
  );

  prettyPrint(
    'Mediator DID Document',
    object: bobMediatorDocument,
  );

  final bobSigner = await bobDidManager.getSigner(
    bobDidDocument.assertionMethod.first.id,
  );

  final alicePlainTextMassage = PlainTextMessage(
    id: const Uuid().v4(),
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

  final aliceSignedAndEncryptedMessage =
      await DidcommMessage.packIntoSignedAndEncryptedMessages(
    alicePlainTextMassage,
    keyType: [bobDidDocument].getCommonKeyTypesInKeyAgreements().first,
    recipientDidDocuments: [bobDidDocument],
    keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    signer: aliceSigner,
  );

  prettyPrint(
    'Encrypted and Signed Message by Alice',
    object: aliceSignedAndEncryptedMessage,
  );

  final createdTime = DateTime.now().toUtc();
  final expiresTime = createdTime.add(const Duration(seconds: 60));

  final forwardMessage = ForwardMessage(
    id: const Uuid().v4(),
    from: aliceDidDocument.id,
    to: [bobMediatorDocument.id],
    next: bobDidDocument.id,
    expiresTime: expiresTime,
    attachments: [
      Attachment(
        mediaType: 'application/json',
        data: AttachmentData(
          base64: base64UrlEncodeNoPadding(
            aliceSignedAndEncryptedMessage.toJsonBytes(),
          ),
        ),
      ),
    ],
  );

  prettyPrint(
    'Forward Message for Mediator that wraps Encrypted Message for Bob',
    object: forwardMessage,
  );


  // Find Alice's P256 key for key agreement
  final aliceP256VerificationMethod = aliceDidDocument.verificationMethod[1];

  // Alice is going to use Bob's Mediator to send him a message
  final aliceMediatorClient = MediatorClient(
    mediatorDidDocument: bobMediatorDocument,
    keyPair: await aliceDidManager.getKeyPairByDidKeyId(
      aliceP256VerificationMethod.didKeyId,
    ),
    didKeyId: aliceP256VerificationMethod.didKeyId,
    signer: aliceSigner,
    forwardMessageOptions: const ForwardMessageOptions(
      shouldSign: true,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    ),
  );


  // authenticate method is not direct part of mediatorClient, but it is extension method
  // this method is need for mediators, that require authentication like an Affinidi mediator
  final aliceTokens = await aliceMediatorClient.authenticate();

  final bobMatchedDidKeyIds = bobDidDocument.matchKeysInKeyAgreement(
    otherDidDocuments: [
      bobMediatorDocument,
      // bob only sends messages to the mediator, so we don't need to match keys with Alice's DID Document
    ],
  );

  final bobMediatorClient = MediatorClient(
    mediatorDidDocument: bobMediatorDocument,
    keyPair: await bobDidManager.getKeyPairByDidKeyId(
      bobMatchedDidKeyIds.first,
    ),
    didKeyId: bobMatchedDidKeyIds.first,
    signer: bobSigner,
  );

  final bobTokens = await bobMediatorClient.authenticate();

  final sentMessage = await aliceMediatorClient.sendMessage(
    forwardMessage,
    accessToken: aliceTokens.accessToken,
  );

  prettyPrint(
    'Encrypted and Signed Forward Message',
    object: sentMessage,
  );

  prettyPrint('Bob is fetching messages...');

  final messageIds = await bobMediatorClient.listInboxMessageIds(
    accessToken: bobTokens.accessToken,
  );

  final messages = await bobMediatorClient.fetchMessages(
    messageIds: messageIds,
    accessToken: bobTokens.accessToken,
  );

  for (final message in messages) {
    final originalPlainTextMessageFromAlice =
        await DidcommMessage.unpackToPlainTextMessage(
      message: message,
      recipientDidManager: bobDidManager,
      expectedMessageWrappingTypes: [
        MessageWrappingType.anoncryptSignPlaintext,
      ],
      expectedSigners: [
        aliceEd25519VerificationMethod.didKeyId,
      ],
    );

    prettyPrint(
      'Unpacked Plain Text Message received by Bob via Mediator',
      object: originalPlainTextMessageFromAlice,
    );
  }
}
