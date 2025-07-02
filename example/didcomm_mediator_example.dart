import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/encoding.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import 'helpers.dart';

void main() async {
  // Run commands below in your terminal to generate keys for Alice and Bob:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/alice_private_key.pem
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance with https://portal.affinidi.com.
  // Copy its DID Document URL into example/mediator/mediator_did.txt.

  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);

  final aliceDidController = DidKeyController(
    wallet: aliceWallet,
    store: InMemoryDidStore(),
  );

  final bobDidController = DidKeyController(
    wallet: bobWallet,
    store: InMemoryDidStore(),
  );

  final aliceKeyId = 'alice-key-1';
  await aliceWallet.generateKey(
    keyId: aliceKeyId,
    keyType: KeyType.p256,
  );

  await aliceDidController.addVerificationMethod(aliceKeyId);
  final aliceDidDocument = await aliceDidController.getDidDocument();

  prettyPrint(
    'Alice DID',
    object: aliceDidDocument.id,
  );

  final aliceSigner = await aliceDidController.getSigner(
    aliceDidDocument.assertionMethod.first.id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final bobKeyId = 'bob-key-1';
  await bobWallet.generateKey(
    keyId: bobKeyId,
    keyType: KeyType.p256,
  );

  await bobDidController.addVerificationMethod(bobKeyId);
  final bobDidDocument = await bobDidController.getDidDocument();

  prettyPrint(
    'Bob DID Document',
    object: bobDidDocument,
  );

  final bobMediatorDocument = await UniversalDIDResolver.resolve(
    await readDid('./example/mediator/mediator_did.txt'),
  );

  final bobSigner = await bobDidController.getSigner(
    bobDidDocument.assertionMethod.first.id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
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

  // find keys whose curve is common in other DID Documents
  final aliceMatchedKeyIds = aliceDidDocument.matchKeysInKeyAgreement(
    otherDidDocuments: [
      bobDidDocument,
    ],
  );

  final aliceSignedAndEncryptedMessage =
      await DidcommMessage.packIntoSignedAndEncryptedMessages(
    alicePlainTextMassage,
    keyPair: await aliceDidController.getKeyPairByDidKeyId(
      aliceMatchedKeyIds.first,
    ),
    didKeyId: aliceMatchedKeyIds.first,
    recipientDidDocuments: [bobDidDocument],
    keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
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

  // Alice is going to use Bob's Mediator to send him a message

  final aliceMediatorClient = MediatorClient(
    mediatorDidDocument: bobMediatorDocument,
    // TODO: add mediator key negotiotion
    keyPair: await aliceDidController.getKeyPairByDidKeyId(
      aliceMatchedKeyIds.first,
    ),
    didKeyId: aliceMatchedKeyIds.first,
    signer: aliceSigner,
    forwardMessageOptions: const ForwardMessageOptions(
      shouldSign: true,
      shouldEncrypt: true,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    ),
  );

  // authenticate method is not direct part of mediatorClient, but it is extension method
  // this method is need for mediators, that require authentication like an Affinidi mediator
  final aliceTokens = await aliceMediatorClient.authenticate();

  final bobMediatorClient = MediatorClient(
    mediatorDidDocument: bobMediatorDocument,
    // TODO: add mediator key negotiotion
    keyPair: await bobDidController.getKeyPairByDidKeyId(
      bobDidDocument.keyAgreement.first.id,
    ),
    didKeyId: bobDidDocument.keyAgreement.first.id,
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

  final messages = await bobMediatorClient.receiveMessages(
    messageIds: messageIds,
    accessToken: bobTokens.accessToken,
  );

  for (final message in messages) {
    final originalPlainTextMessageFromAlice =
        await DidcommMessage.unpackToPlainTextMessage(
      message: message,
      recipientDidController: bobDidController,
      expectedMessageWrappingTypes: [
        MessageWrappingType.authcryptSignPlaintext,
      ],
      expectedSigners: [
        aliceSigner.didKeyId,
      ],
    );

    prettyPrint(
      'Unpacked Plain Text Message received by Bob via Mediator',
      object: originalPlainTextMessageFromAlice,
    );
  }
}
