import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import '../test/example_configs.dart';

void main() async {
  // Run commands below in your terminal to generate keys for Receiver:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance https://github.com/affinidi/affinidi-tdk-rs/tree/main/crates/affinidi-messaging/affinidi-messaging-mediator or with https://portal.affinidi.com.
  // Copy its DID Document URL into example/mediator/mediator_did.txt.

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
  );

  prettyPrint('Receiver is fetching messages...');

  final messageIds = await receiverMediatorClient.listInboxMessageIds();

  final messages = await receiverMediatorClient.fetchMessages(
    messageIds: messageIds,
  );

  for (final message in messages) {
    final originalPlainTextMessageFromSender =
        await DidcommMessage.unpackToPlainTextMessage(
      message: message,
      recipientDidManager: receiverDidManager,
      expectedMessageWrappingTypes: [
        MessageWrappingType.anoncryptSignPlaintext,
      ],
    );

    prettyPrint(
      'Unpacked Plain Text Message received by Receiver via Mediator',
      object: originalPlainTextMessageFromSender,
    );
  }
}
