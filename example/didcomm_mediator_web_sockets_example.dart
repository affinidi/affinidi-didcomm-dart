import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/did_document_service_type.dart';
import 'package:didcomm/src/common/encoding.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/extensions/verification_method_list_extention.dart';
import 'package:didcomm/src/messages/algorithm_types/algorithms_types.dart';
import 'package:didcomm/src/messages/attachments/attachment.dart';
import 'package:didcomm/src/messages/attachments/attachment_data.dart';
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

  final aliceKeyId = 'alice-key-1';
  final alicePrivateKeyBytes =
      await extractPrivateKeyBytes('./example/keys/alice_private_key.pem');

  await aliceKeyStore.set(
    aliceKeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: alicePrivateKeyBytes,
    ),
  );

  final aliceKeyPair = await aliceWallet.getKeyPair(aliceKeyId);
  final aliceDidDocument = DidKey.generateDocument(aliceKeyPair.publicKey);

  prettyPrint('Alice DID', aliceDidDocument.id);

  final aliceSigner = DidSigner(
    didDocument: aliceDidDocument,
    keyPair: aliceKeyPair,
    didKeyId: aliceDidDocument.verificationMethod[0].id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final bobKeyId = 'bob-key-1';
  final bobPrivateKeyBytes =
      await extractPrivateKeyBytes('./example/keys/bob_private_key.pem');

  await bobKeyStore.set(
    bobKeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: bobPrivateKeyBytes,
    ),
  );

  final bobKeyPair = await bobWallet.getKeyPair(bobKeyId);
  final bobDidDocument = DidKey.generateDocument(bobKeyPair.publicKey);

  await bobDidDocument.copyServicesByTypeFromResolvedDid(
    DidDocumentServiceType.didCommMessaging,
    await readDid('./example/mediator/mediator_did.txt'),
  );

  // Serialized bobDidDocument needs to shared with sender
  prettyPrint('Bob DID Document', bobDidDocument);

  final bobMediatorDocument = await UniversalDIDResolver.resolve(
    bobDidDocument.getFirstServiceDidByType(
      DidDocumentServiceType.didCommMessaging,
    )!,
  );

  final bobSigner = DidSigner(
    didDocument: bobDidDocument,
    keyPair: bobKeyPair,
    didKeyId: bobDidDocument.verificationMethod[0].id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final bobJwks = bobDidDocument.keyAgreement.toJwks();

  for (var jwk in bobJwks.keys) {
    // Important! link JWK, so the wallet should be able to find the key pair by JWK
    // It will be replaced with DID Manager
    bobWallet.linkJwkKeyIdKeyWithKeyId(jwk.keyId!, bobKeyId);
  }

  final alicePlainTextMassage = PlainTextMessage(
    id: Uuid().v4(),
    from: aliceDidDocument.id,
    to: [bobDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': 'Hello, Bob!'},
  );

  alicePlainTextMassage['custom-header'] = 'custom-value';
  prettyPrint('Plain Text Message for Bob', alicePlainTextMassage);

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

  prettyPrint(
    'Encrypted and Signed Message by Alice',
    aliceSignedAndEncryptedMessage,
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

  prettyPrint(
    'Forward Message for Mediator that wraps Encrypted Message for Bob',
    forwardMessage,
  );

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
      ));

  // authenticate method is not direct part of mediatorClient, but it is extension method
  // this method is need for mediators, that require authentication like an Affinidi mediator
  final aliceTokens = await aliceMediatorClient.authenticate();

  final bobMediatorClient = MediatorClient(
    mediatorDidDocument: bobMediatorDocument,
    wallet: bobWallet,
    keyId: bobKeyId,
    signer: bobSigner,
    webSocketOptions: WebSocketOptions(
      statusRequestMessageOptions: StatusRequestMessageOptions(
        shouldSend: true,
      ),
      liveDeliveryChangeMessageOptions: LiveDeliveryChangeMessageOptions(
        shouldSend: true,
      ),
    ),
  );

  final bobTokens = await bobMediatorClient.authenticate();

  print('Bob is waiting for a message...');

  await bobMediatorClient.listenForIncomingMessages(
    (message) async {
      final unpackedMessageByBob =
          await DidcommMessage.unpackToPlainTextMessage(
        message: message,
        recipientWallet: bobWallet,
      );

      prettyPrint(
        'Unpacked Plain Text Message received by Bob via Mediator',
        unpackedMessageByBob,
      );

      await bobMediatorClient.disconnect();
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
}
