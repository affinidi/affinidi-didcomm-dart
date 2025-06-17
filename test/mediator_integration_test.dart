import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/did_document_service_type.dart';
import 'package:didcomm/src/common/encoding.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/extensions/verification_method_list_extention.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/algorithms_types.dart';
import 'package:didcomm/src/messages/attachments/attachment.dart';
import 'package:didcomm/src/messages/attachments/attachment_data.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../example/helpers.dart';

void main() async {
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

  await writeEnvironmentVariableToFileIfNeed(
    'TEST_MEDIATOR_DID',
    mediatorDidPath,
  );

  await writeEnvironmentVariableToFileIfNeed(
    'TEST_ALICE_PRIVATE_KEY_PEM',
    alicePrivateKeyPath,
  );

  await writeEnvironmentVariableToFileIfNeed(
    'TEST_BOB_PRIVATE_KEY_PEM',
    bobPrivateKeyPath,
  );

  group('Mediator Integration Test', () {
    late String aliceKeyId;
    late PersistentWallet aliceWallet;
    late DidSigner aliceSigner;
    late DidDocument aliceDidDocument;

    late String bobKeyId;
    late PersistentWallet bobWallet;
    late DidSigner bobSigner;
    late DidDocument bobDidDocument;
    late Jwks bobJwks;

    late DidDocument bobMediatorDocument;

    setUp(() async {
      final aliceKeyStore = InMemoryKeyStore();
      aliceWallet = PersistentWallet(aliceKeyStore);

      final bobKeyStore = InMemoryKeyStore();
      bobWallet = PersistentWallet(bobKeyStore);

      aliceKeyId = 'alice-key-1';
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

      final aliceKeyPair = await aliceWallet.getKeyPair(aliceKeyId);
      aliceDidDocument = DidKey.generateDocument(aliceKeyPair.publicKey);

      aliceSigner = DidSigner(
        didDocument: aliceDidDocument,
        keyPair: aliceKeyPair,
        didKeyId: aliceDidDocument.verificationMethod[0].id,
        signatureScheme: SignatureScheme.ecdsa_p256_sha256,
      );

      bobKeyId = 'bob-key-1';
      final bobPrivateKeyBytes = await extractPrivateKeyBytes(
        bobPrivateKeyPath,
      );

      await bobKeyStore.set(
        bobKeyId,
        StoredKey(
          keyType: KeyType.p256,
          privateKeyBytes: bobPrivateKeyBytes,
        ),
      );

      final bobKeyPair = await bobWallet.getKeyPair(bobKeyId);
      bobDidDocument = DidKey.generateDocument(bobKeyPair.publicKey);

      await bobDidDocument.copyServicesByTypeFromResolvedDid(
        DidDocumentServiceType.didCommMessaging,
        await readDid(mediatorDidPath),
      );

      bobSigner = DidSigner(
        didDocument: bobDidDocument,
        keyPair: bobKeyPair,
        didKeyId: bobDidDocument.verificationMethod[0].id,
        signatureScheme: SignatureScheme.ecdsa_p256_sha256,
      );

      bobJwks = bobDidDocument.keyAgreement.toJwks();

      for (var jwk in bobJwks.keys) {
        // Important! link JWK, so the wallet should be able to find the key pair by JWK
        // It will be replaced with DID Manager
        bobWallet.linkJwkKeyIdKeyWithKeyId(jwk.keyId!, bobKeyId);
      }

      bobMediatorDocument = await UniversalDIDResolver.resolve(
        bobDidDocument.getFirstServiceDidByType(
          DidDocumentServiceType.didCommMessaging,
        )!,
      );
    });

    test('REST API works correctly', () async {
      final alicePlainTextMassage = PlainTextMessage(
        id: Uuid().v4(),
        from: aliceDidDocument.id,
        to: [bobDidDocument.id],
        type: Uri.parse('https://didcomm.org/example/1.0/message'),
        body: {'content': 'Hello, Bob!'},
      );

      alicePlainTextMassage['custom-header'] = 'custom-value';

      final aliceSignedAndEncryptedMessage =
          await DidcommMessage.packIntoSignedAndEncryptedMessages(
        alicePlainTextMassage,
        wallet: aliceWallet,
        keyId: aliceKeyId,
        jwksPerRecipient: [bobJwks],
        keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
        encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
        signer: aliceSigner,
      );

      final createdTime = DateTime.now().toUtc();
      final expiresTime = createdTime.add(const Duration(seconds: 60));

      final forwardMessage = ForwardMessage(
        id: Uuid().v4(),
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

      // Alice is going to use Bob's Mediator to send him a message

      final aliceMediatorClient = MediatorClient(
        mediatorDidDocument: bobMediatorDocument,
        wallet: aliceWallet,
        keyId: aliceKeyId,
        signer: aliceSigner,

        // optional. if omitted defaults will be used
        forwardMessageOptions: ForwardMessageOptions(
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
        wallet: bobWallet,
        keyId: bobKeyId,
        signer: bobSigner,
      );

      final bobTokens = await bobMediatorClient.authenticate();

      await aliceMediatorClient.sendMessage(
        forwardMessage,
        accessToken: aliceTokens.accessToken,
      );

      final messageIds = await bobMediatorClient.listInboxMessageIds(
        accessToken: bobTokens.accessToken,
      );

      final messages = await bobMediatorClient.receiveMessages(
        messageIds: messageIds,
        accessToken: bobTokens.accessToken,
      );

      assert(messages.isNotEmpty, isTrue);
    });
  });
}
