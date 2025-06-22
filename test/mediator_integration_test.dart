import 'package:collection/collection.dart';
import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/authentication_tokens/authentication_tokens.dart';
import 'package:didcomm/src/common/did_document_service_type.dart';
import 'package:didcomm/src/common/encoding.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../example/helpers.dart';

// sometimes websockets connection is dropped
// it is better to delegate connection restoration strategy for the application, that uses this library
const webSocketsTestRetries = 2;

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
    decodeBase64: true,
  );

  await writeEnvironmentVariableToFileIfNeed(
    'TEST_BOB_PRIVATE_KEY_PEM',
    bobPrivateKeyPath,
    decodeBase64: true,
  );

  group('Mediator Integration Test', () {
    late PersistentWallet aliceWallet;
    late DidSigner aliceSigner;
    late DidDocument aliceDidDocument;
    late MediatorClient aliceMediatorClient;
    late AuthenticationTokens aliceTokens;

    late PersistentWallet bobWallet;
    late DidSigner bobSigner;
    late DidDocument bobDidDocument;
    late MediatorClient bobMediatorClient;
    late AuthenticationTokens bobTokens;

    late DidDocument bobMediatorDocument;

    setUp(() async {
      final aliceKeyStore = InMemoryKeyStore();
      aliceWallet = PersistentWallet(aliceKeyStore);

      final bobKeyStore = InMemoryKeyStore();
      bobWallet = PersistentWallet(bobKeyStore);

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

      final aliceKeyPair = await aliceWallet.getKeyPair(aliceKeyId);
      aliceDidDocument = DidKey.generateDocument(aliceKeyPair.publicKey);

      aliceSigner = DidSigner(
        didDocument: aliceDidDocument,
        keyPair: aliceKeyPair,
        didKeyId: aliceDidDocument.verificationMethod[0].id,
        signatureScheme: SignatureScheme.ecdsa_p256_sha256,
      );

      for (var keyAgreement in aliceDidDocument.keyAgreement) {
        // Important! link JWK, so the wallet should be able to find the key pair by JWK
        // It will be replaced with DID Manager
        aliceWallet.linkDidKeyIdKeyWithKeyId(keyAgreement.id, aliceKeyId);
      }

      final bobKeyId = 'bob-key-1';
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

      for (var keyAgreement in bobDidDocument.keyAgreement) {
        // Important! link JWK, so the wallet should be able to find the key pair by JWK
        // It will be replaced with DID Manager
        bobWallet.linkDidKeyIdKeyWithKeyId(keyAgreement.id, bobKeyId);
      }

      bobMediatorDocument = await UniversalDIDResolver.resolve(
        bobDidDocument.getFirstServiceDidByType(
          DidDocumentServiceType.didCommMessaging,
        )!,
      );

      final aliceMatchedKeyIds = aliceDidDocument.getKeyIdsWithCommonType(
        wallet: aliceWallet,
        otherDidDocuments: [
          bobDidDocument,
        ],
      );

      aliceMediatorClient = MediatorClient(
        mediatorDidDocument: bobMediatorDocument,
        keyPair: aliceKeyPair,
        didKeyId: aliceWallet.getDidIdByKeyId(aliceMatchedKeyIds.first)!,
        signer: aliceSigner,

        // optional. if omitted defaults will be used
        forwardMessageOptions: ForwardMessageOptions(
          shouldSign: true,
          shouldEncrypt: true,
          keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
          encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
        ),
      );

      bobMediatorClient = MediatorClient(
        mediatorDidDocument: bobMediatorDocument,
        keyPair: bobKeyPair,
        didKeyId: bobWallet.getDidIdByKeyId(bobKeyId)!,
        signer: bobSigner,

        // optional. if omitted defaults will be used
        webSocketOptions: WebSocketOptions(
          liveDeliveryChangeMessageOptions: LiveDeliveryChangeMessageOptions(
            shouldSend: true,
            shouldSign: true,
            shouldEncrypt: true,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
            encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
          ),
          statusRequestMessageOptions: StatusRequestMessageOptions(
            shouldSend: true,
            shouldSign: true,
            shouldEncrypt: true,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
            encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
          ),
        ),
      );

      aliceTokens = await aliceMediatorClient.authenticate();
      bobTokens = await bobMediatorClient.authenticate();
    });

    test('REST API works correctly', () async {
      final expectedBodyContent = Uuid().v4();

      final alicePlainTextMassage = PlainTextMessage(
        id: Uuid().v4(),
        from: aliceDidDocument.id,
        to: [bobDidDocument.id],
        type: Uri.parse('https://didcomm.org/example/1.0/message'),
        body: {'content': expectedBodyContent},
      );

      alicePlainTextMassage['custom-header'] = 'custom-value';

      // find keys whose curve is common in other DID Documents
      final aliceMatchedKeyIds = aliceDidDocument.getKeyIdsWithCommonType(
        wallet: aliceWallet,
        otherDidDocuments: [
          bobDidDocument,
        ],
      );

      final aliceSignedAndEncryptedMessage =
          await DidcommMessage.packIntoSignedAndEncryptedMessages(
        alicePlainTextMassage,
        keyPair: await aliceWallet.getKeyPair(aliceMatchedKeyIds.first),
        didKeyId: aliceWallet.getDidIdByKeyId(aliceMatchedKeyIds.first)!,
        recipientDidDocuments: [bobDidDocument],
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

      expect(messages.isNotEmpty, isTrue);

      final actualUnpackedMessages = await Future.wait(
        messages.map(
          (message) => DidcommMessage.unpackToPlainTextMessage(
            message: message,
            recipientWallet: bobWallet,
          ),
        ),
      );

      final actualBodyContents = actualUnpackedMessages
          .map<String?>((message) => message.body?['content'])
          .toList();

      expect(
        actualBodyContents.singleWhereOrNull(
          (content) => content == expectedBodyContent,
        ),
        isNotNull,
      );
    });

    test(
      'WebSockets API works correctly',
      () async {
        final expectedBodyContent = Uuid().v4();

        final alicePlainTextMassage = PlainTextMessage(
          id: Uuid().v4(),
          from: aliceDidDocument.id,
          to: [bobDidDocument.id],
          type: Uri.parse('https://didcomm.org/example/1.0/message'),
          body: {'content': expectedBodyContent},
        );

        alicePlainTextMassage['custom-header'] = 'custom-value';

        final aliceMatchedKeyIds = aliceDidDocument.getKeyIdsWithCommonType(
          wallet: aliceWallet,
          otherDidDocuments: [
            bobDidDocument,
          ],
        );

        final aliceSignedAndEncryptedMessage =
            await DidcommMessage.packIntoSignedAndEncryptedMessages(
          alicePlainTextMassage,
          keyPair: await aliceWallet.getKeyPair(aliceMatchedKeyIds.first),
          didKeyId: aliceWallet.getDidIdByKeyId(aliceMatchedKeyIds.first)!,
          recipientDidDocuments: [bobDidDocument],
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

        String? actualBodyContent;

        await bobMediatorClient.listenForIncomingMessages(
          (message) async {
            final unpackedMessage =
                await DidcommMessage.unpackToPlainTextMessage(
              message: message,
              recipientWallet: bobWallet,
            );

            final content = unpackedMessage.body?['content'];

            if (content == expectedBodyContent) {
              actualBodyContent = content;
              await bobMediatorClient.disconnect();
            }
          },
          onError: (error) => print(error),
          onDone: () => print('done'),
          accessToken: bobTokens.accessToken,
          cancelOnError: false,
        );

        await aliceMediatorClient.sendMessage(
          forwardMessage,
          accessToken: aliceTokens.accessToken,
        );

        expect(actualBodyContent, expectedBodyContent);
      },
      retry: webSocketsTestRetries,
    );
  });
}
