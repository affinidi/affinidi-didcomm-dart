import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/extensions/affinidi_atlas_management_extension.dart';
import 'package:ssi/ssi.dart';

import '../test/example_configs.dart';

void main() async {
  // Run commands below in your terminal to generate keys for Receiver:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance https://github.com/affinidi/affinidi-tdk-rs/tree/main/crates/affinidi-messaging/affinidi-messaging-mediator or with https://portal.affinidi.com.
  // Copy its DID Document URL into example/mediator/mediator_did.txt.

  // Replace this DID Document with your receiver DID Document
  final gatewayDidDocument =
      await UniversalDIDResolver.defaultResolver.resolveDid(
    'did:web:did.dev.affinidi.io:ama',
  );

  final senderKeyStore = InMemoryKeyStore();
  final senderWallet = PersistentWallet(senderKeyStore);

  final senderDidManager = DidPeerManager(
    wallet: senderWallet,
    store: InMemoryDidStore(),
  );

  final senderKeyId = 'alice-key-1';
  final senderPrivateKeyBytes =
      await extractPrivateKeyBytes(alicePrivateKeyPath);

  await senderKeyStore.set(
    senderKeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: senderPrivateKeyBytes,
    ),
  );

  await senderDidManager.addVerificationMethod(senderKeyId);
  final senderDidDocument = await senderDidManager.getDidDocument();

  prettyPrint(
    'Sender DID Document',
    object: senderDidDocument,
  );

  final senderSigner = await senderDidManager.getSigner(
    senderDidDocument.authentication.first.id,
  );

  final mediatorDidDocument =
      await UniversalDIDResolver.defaultResolver.resolveDid(
    await readDid(mediatorDidPath),
  );

  // find keys whose curve is common in other DID Documents
  final senderMatchedDidKeyIds = senderDidDocument.matchKeysInKeyAgreement(
    otherDidDocuments: [
      gatewayDidDocument,
    ],
  );

  final mediatorClient = MediatorClient(
    mediatorDidDocument: mediatorDidDocument,
    keyPair: await senderDidManager.getKeyPairByDidKeyId(
      senderMatchedDidKeyIds.first,
    ),
    didKeyId: senderMatchedDidKeyIds.first,
    signer: senderSigner,
    // optional. if omitted defaults will be used
    forwardMessageOptions: const ForwardMessageOptions(
      shouldSign: true,
      shouldEncrypt: true,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    ),
    webSocketOptions: const WebSocketOptions(
      statusRequestMessageOptions: StatusRequestMessageOptions(
        shouldSend: true,
        shouldSign: true,
        shouldEncrypt: true,
      ),
      liveDeliveryChangeMessageOptions: LiveDeliveryChangeMessageOptions(
        shouldSend: true,
        shouldSign: true,
        shouldEncrypt: true,
      ),
    ),
  );

  // authenticate method is not direct part of mediatorClient, but it is extension method
  // this method is need for mediators, that require authentication like an Affinidi mediator
  final authTokes = await mediatorClient.authenticate();

  final gatewayClient = AffinidiDidcommGatewayClient(
    mediatorClient: mediatorClient,
    didcommGatewayDidDocument: gatewayDidDocument,
    signer: senderSigner,
    keyPair: await senderDidManager.getKeyPairByDidKeyId(
      senderMatchedDidKeyIds.first,
    ),
    didKeyId: senderMatchedDidKeyIds.first,
  );

  await mediatorClient.listenForIncomingMessages(
    (message) async {
      final encryptedMessage = EncryptedMessage.fromJson(message);
      final senderDid = const JweHeaderConverter()
          .fromJson(encryptedMessage.protected)
          .subjectKeyId;

      final isMediatorTelemetryMessage =
          senderDid?.contains('.affinidi.io') == true;

      final unpackedMessageByBob =
          await DidcommMessage.unpackToPlainTextMessage(
        message: message,
        recipientDidManager: senderDidManager,
        expectedMessageWrappingTypes: [
          isMediatorTelemetryMessage
              ? MessageWrappingType.authcryptSignPlaintext
              : MessageWrappingType.anoncryptSignPlaintext,
        ],
      );

      prettyPrint(
        'Unpacked Plain Text Message received by Bob via Mediator',
        object: unpackedMessageByBob,
      );

//      await mediatorClient.disconnect();
    },
    onError: (dynamic error) => prettyPrint('error', object: error),
    onDone: () => prettyPrint('done'),
    accessToken: authTokes.accessToken,
    cancelOnError: false,
  );

  await gatewayClient.getMediators(
    accessToken: authTokes.accessToken,
  );

  prettyPrint('The message has been sent');
}
