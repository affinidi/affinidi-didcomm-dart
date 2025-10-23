import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import '../test/example_configs.dart';

void main() async {
  // Run commands below in your terminal to generate keys for Receiver:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance https://github.com/affinidi/affinidi-tdk-rs/tree/main/crates/affinidi-messaging/affinidi-messaging-mediator or with https://portal.affinidi.com.
  // Copy its DID Document URL into example/mediator/mediator_did.txt.

  // The sender's DID is needed to configure ACL if the mediator requires it
  // did:key:......
  final senderDid = await getDidKeyForPrivateKeyPath(alicePrivateKeyPath);

  final receiverKeyStore = InMemoryKeyStore();
  final receiverWallet = PersistentWallet(receiverKeyStore);

  final receiverDidManager = DidKeyManager(
    wallet: receiverWallet,
    store: InMemoryDidStore(),
  );

  final receiverKeyId = 'receiver-key-1';

  final receiverPrivateKeyBytes = await extractPrivateKeyBytes(
    bobPrivateKeyPath,
  );

  await receiverKeyStore.set(
    receiverKeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: receiverPrivateKeyBytes,
    ),
  );

  await receiverDidManager.addVerificationMethod(receiverKeyId);
  final receiverDidDocument = await receiverDidManager.getDidDocument();

  // Serialized receiverMediatorDocument needs to shared with sender
  prettyPrint(
    'Receiver DID Document',
    object: receiverDidDocument,
  );

  final receiverMediatorDocument =
      await UniversalDIDResolver.defaultResolver.resolveDid(
    await readDid(mediatorDidPath),
  );

  final receiverMediatorClient = await MediatorClient.init(
    mediatorDidDocument: receiverMediatorDocument,
    didManager: receiverDidManager,
    authorizationProvider: await AffinidiAuthorizationProvider.init(
      mediatorDidDocument: receiverMediatorDocument,
      didManager: receiverDidManager,
    ),
    forwardMessageOptions: const ForwardMessageOptions(
      shouldSign: true,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    ),
  );

  // configure ACL to allow Alice to send messages to Bob via his mediator
  // need only if the mediator requires ACL management
  await configureAcl(
    ownDidDocument: receiverDidDocument,
    theirDids: [senderDid],
    mediatorClient: receiverMediatorClient,
    expiresTime: DateTime.now().toUtc().add(
          const Duration(minutes: 3),
        ),
  );

  prettyPrint('Receiver is fetching messages...');

  final messages = await receiverMediatorClient.fetchMessages();

  for (final message in messages) {
    final originalPlainTextMessageFromSender =
        await DidcommMessage.unpackToPlainTextMessage(
      message: message,
      recipientDidManager: receiverDidManager,
      expectedMessageWrappingTypes: [
        MessageWrappingType.anoncryptSignPlaintext,
        MessageWrappingType.authcryptSignPlaintext,
        MessageWrappingType.authcryptPlaintext,
        MessageWrappingType.anoncryptAuthcryptPlaintext,
      ],
    );

    prettyPrint(
      'Unpacked Plain Text Message received by Receiver via Mediator',
      object: originalPlainTextMessageFromSender,
    );
  }
}
