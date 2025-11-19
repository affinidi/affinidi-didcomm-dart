import 'dart:io';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../test/example_configs.dart';

const messageCount = 5;

Future<ForwardMessage> getForwardMessage(
    DidDocument aliceDidDocument,
    DidDocument bobDidDocument,
    DidDocument bobMediatorDocument,
    DidSigner aliceSigner,
    DateTime expiresTime,
    String content) async {
  final alicePlainTextMassage = PlainTextMessage(
    id: const Uuid().v4(),
    from: aliceDidDocument.id,
    to: [bobDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': content},
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

  return forwardMessage;
}

void main() async {
  // Run commands below in your terminal to generate keys for Alice and Bob:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/alice_private_key.pem
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance https://github.com/affinidi/affinidi-tdk-rs/tree/main/crates/affinidi-messaging/affinidi-messaging-mediator or with https://portal.affinidi.com.
  // Copy its DID Document URL into example/mediator/mediator_did.txt.

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
  final alicePrivateKeyBytes = await extractPrivateKeyBytes(
    alicePrivateKeyPath,
  );

  await aliceKeyStore.set(
    aliceKeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: alicePrivateKeyBytes,
    ),
  );

  await aliceDidManager.addVerificationMethod(aliceKeyId);
  final aliceDidDocument = await aliceDidManager.getDidDocument();

  prettyPrint(
    'Alice DID',
    object: aliceDidDocument.id,
  );

  final aliceSigner = await aliceDidManager.getSigner(
    aliceDidDocument.assertionMethod.first.id,
  );

  final bobKeyId = 'bob-key-1';
  final bobPrivateKeyBytes = await extractPrivateKeyBytes(bobPrivateKeyPath);

  await bobKeyStore.set(
    bobKeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: bobPrivateKeyBytes,
    ),
  );

  await bobDidManager.addVerificationMethod(bobKeyId);
  final bobDidDocument = await bobDidManager.getDidDocument();

  // Serialized bobDidDocument needs to shared with sender
  prettyPrint(
    'Bob DID Document',
    object: bobDidDocument,
  );

  final bobMediatorDocument =
      await UniversalDIDResolver.defaultResolver.resolveDid(
    await readDid(mediatorDidPath),
  );

  final aliceMediatorClient = await MediatorClient.init(
    mediatorDidDocument: bobMediatorDocument,
    didManager: aliceDidManager,
    authorizationProvider: await AffinidiAuthorizationProvider.init(
      mediatorDidDocument: bobMediatorDocument,
      didManager: aliceDidManager,
    ),
    forwardMessageOptions: const ForwardMessageOptions(
      shouldSign: true,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    ),
  );

  final bobMediatorClient = await MediatorClient.init(
    mediatorDidDocument: bobMediatorDocument,
    didManager: bobDidManager,
    authorizationProvider: await AffinidiAuthorizationProvider.init(
      mediatorDidDocument: bobMediatorDocument,
      didManager: bobDidManager,
    ),
    onReconnecting: ({
      closeCode,
      closeReason,
    }) =>
        prettyPrint(
      'Bob Mediator Client reconnecting',
      object: {
        'closeCode': closeCode,
        'closeReason': closeReason,
      },
    ),
    onReconnected: () => prettyPrint(
      'Bob Mediator Client reconnected',
    ),
    webSocketOptions: const WebSocketOptions(
      deleteOnMediator: false,
      deleteOnWsConnection: false,
      statusRequestMessageOptions: StatusRequestMessageOptions(
        shouldSend: true,
        shouldSign: true,
      ),
      liveDeliveryChangeMessageOptions: LiveDeliveryChangeMessageOptions(
        shouldSend: true,
        shouldSign: true,
      ),
    ),
    forwardMessageOptions: const ForwardMessageOptions(
      shouldSign: true,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    ),
  );

  final createdTime = DateTime.now().toUtc();
  final expiresTime = createdTime.add(const Duration(seconds: 600));

  // configure ACL to allow Alice to send messages to Bob via his mediator
  // need only if the mediator requires ACL management
  await configureAcl(
    ownDidDocument: bobDidDocument,
    theirDids: [aliceDidDocument.id],
    mediatorClient: bobMediatorClient,
    expiresTime: expiresTime,
  );

  prettyPrint('Bob is waiting for a message...');

  bobMediatorClient.listenForIncomingMessages(
    (message) async {
      final unpackedMessageByBob =
          await DidcommMessage.unpackToPlainTextMessage(
        message: message,
        recipientDidManager: bobDidManager,
        expectedMessageWrappingTypes: [
          MessageWrappingType.anoncryptSignPlaintext,
          MessageWrappingType.authcryptSignPlaintext,
          MessageWrappingType.authcryptPlaintext,
          MessageWrappingType.anoncryptAuthcryptPlaintext,
        ],
      );

      prettyPrint(
        'Unpacked Plain Text Message received by Bob via Mediator',
        object: unpackedMessageByBob.body,
      );
    },
    onError: (dynamic error) => prettyPrint('error', object: error),
    onDone: ({int? closeCode, String? closeReason}) => prettyPrint('done'),
    cancelOnError: false,
  );

  final initialMessages =
      await bobMediatorClient.fetchMessages(deleteOnMediator: true);
  prettyPrint(
    'messages.length before: ${initialMessages.length}',
  );

  prettyPrint('ConnectionPool.instance.startConnections');
  await ConnectionPool.instance.startConnections();

  for (var i = 1; i <= messageCount; i++) {
    await aliceMediatorClient.sendMessage(
      await getForwardMessage(
          aliceDidDocument,
          bobDidDocument,
          bobMediatorDocument,
          aliceSigner,
          expiresTime,
          'Hello, Bob #$messageCount!'),
    );
  }

  sleep(const Duration(seconds: 2));

  await ConnectionPool.instance.stopConnections();
  prettyPrint('ConnectionPool.instance.stopConnections');

  sleep(const Duration(seconds: 2));

  final aliceMessages =
      await bobMediatorClient.fetchMessages(deleteOnMediator: false);
  prettyPrint(
    'aliceMessages.length: ${aliceMessages.length}',
  );
  if (aliceMessages.length != messageCount) {
    throw StateError(
      'Expected $messageCount messages, but got ${aliceMessages.length}',
    );
  }
  final messagesAfter =
      await bobMediatorClient.fetchMessages(deleteOnMediator: true);
  prettyPrint(
    'messagesAfter.length: ${messagesAfter.length}',
  );

  final messagesFinal =
      await bobMediatorClient.fetchMessages(deleteOnMediator: true);
  prettyPrint(
    'messagesFinal.length: ${messagesFinal.length}',
  );
}
