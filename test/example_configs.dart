import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

// Run commands below in your terminal to generate keys for Alice and Bob:
// openssl ecparam -name prime256v1 -genkey -noout -out example/keys/alice_private_key.pem
// openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem
// OR
// set environment variables TEST_MEDIATOR_DID, TEST_ALICE_PRIVATE_KEY_PEM, and TEST_BOB_PRIVATE_KEY_PEM

// Create and run a DIDComm mediator, for instance with https://portal.affinidi.com.
// Copy its DID Document URL into example/mediator/mediator_did.txt.

const mediatorDidPath = './example/mediator/mediator_did.txt';
const alicePrivateKeyPath = './example/keys/alice_private_key.pem';
const bobPrivateKeyPath = './example/keys/bob_private_key.pem';

/// Configures files based on ENV vars.
Future<void> configureTestFiles() async {
  await writeEnvironmentVariableToFileIfNeeded(
    'TEST_MEDIATOR_DID',
    mediatorDidPath,
  );

  await writeEnvironmentVariableToFileIfNeeded(
    'TEST_ALICE_PRIVATE_KEY_PEM',
    alicePrivateKeyPath,
    decodeBase64: true,
  );

  await writeEnvironmentVariableToFileIfNeeded(
    'TEST_BOB_PRIVATE_KEY_PEM',
    bobPrivateKeyPath,
    decodeBase64: true,
  );
}

Future<void> configureAcl({
  required DidDocument ownDidDocument,
  required List<String> theirDids,
  required MediatorClient mediatorClient,
  DateTime? expiresTime,
}) async {
  final accessListAddMessage = AccessListAddMessage(
    id: const Uuid().v4(),
    from: ownDidDocument.id,
    to: [mediatorClient.mediatorDidDocument.id],
    theirDids: theirDids,
    expiresTime: expiresTime,
  );

  await mediatorClient.sendAclManagementMessage(
    accessListAddMessage,
  );
}

Future<String> getDidKeyForPrivateKeyPath(String privateKeyPath) async {
  final keyStore = InMemoryKeyStore();
  final wallet = PersistentWallet(keyStore);

  final didManager = DidKeyManager(
    wallet: wallet,
    store: InMemoryDidStore(),
  );

  final keyId = 'key-1';

  final privateKeyBytes = await extractPrivateKeyBytes(
    bobPrivateKeyPath,
  );

  await keyStore.set(
    keyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: privateKeyBytes,
    ),
  );

  await didManager.addVerificationMethod(keyId);
  final receiverDidDocument = await didManager.getDidDocument();

  return receiverDidDocument.id;
}
