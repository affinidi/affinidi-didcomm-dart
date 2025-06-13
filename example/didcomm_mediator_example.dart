import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/did_document_service_type.dart';
import 'package:didcomm/src/common/encoding.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/encryption_algorithm.dart';
import 'package:didcomm/src/messages/attachments/attachment.dart';
import 'package:didcomm/src/messages/attachments/attachment_data.dart';
import 'package:didcomm/src/messages/didcomm_message.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import 'helpers.dart';

void main() async {
  // Run commands below in your terminal to generate keys for Alice and Bob:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/alice_private_key.pem
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance with https://portal.affinidi.com. Copy its DID Document into example/mediator/mediator_did_document.json.
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

  // TODO: authentication service is temporary needed until Affinidi Mediator is updated
  bobDidDocument.copyServicesByTypeFromResolvedDid(
    DidDocumentServiceType.authentication,
    await readDid('./example/mediator/mediator_did.txt'),
  );

  final bobMediatorDocument = await UniversalDIDResolver.resolve(
    bobDidDocument
        .getFirstServiceDidByType(DidDocumentServiceType.didCommMessaging)!,
  );

  prettyPrint('Bob DID', bobDidDocument.id);
  prettyPrint('Bob Mediator DID', bobMediatorDocument.id);

  final bobSigner = DidSigner(
    didDocument: bobDidDocument,
    keyPair: bobKeyPair,
    didKeyId: bobDidDocument.verificationMethod[0].id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  // TODO: kid is not available in the Jwk anymore. clarify with the team
  final bobJwk = bobDidDocument.keyAgreement[0].asJwk().toJson();
  bobJwk['kid'] =
      '${bobDidDocument.id}#${bobDidDocument.id.replaceFirst('did:key:', '')}';

  // Important! link JWK, so the wallet should be able to find the key pair by JWK
  bobWallet.linkJwkKeyIdKeyWithKeyId(bobJwk['kid']!, bobKeyId);

  final plainTextMassage = PlainTextMessage(
    id: Uuid().v4(),
    from: aliceDidDocument.id,
    to: [bobDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': 'Hello, Bob!'},
  );

  plainTextMassage['custom-header'] = 'custom-value';

  prettyPrint('Plain Text Message for Bob', plainTextMassage);

  final signedMessageByAlice = await SignedMessage.pack(
    plainTextMassage,
    signer: aliceSigner,
  );
  prettyPrint('Signed Message for Bob', signedMessageByAlice);

  final encryptedMessageByAlice = await EncryptedMessage.packWithAuthentication(
    signedMessageByAlice,
    wallet: aliceWallet,
    keyId: aliceKeyId,
    jwksPerRecipient: [
      Jwks.fromJson({
        'keys': [bobJwk],
      }),
    ],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  prettyPrint('Encrypted Message for Bob', encryptedMessageByAlice);

  final createdTime = DateTime.now().toUtc();
  final expiresTime = createdTime.add(const Duration(seconds: 60));

  final forwardMessageByAlice = ForwardMessage(
    id: Uuid().v4(),
    to: [bobMediatorDocument.id],
    next: bobDidDocument.id,
    expiresTime: expiresTime,
    attachments: [
      Attachment(
        mediaType: 'application/json',
        data: AttachmentData(
          base64: base64UrlEncodeNoPadding(
            encryptedMessageByAlice.toJsonBytes(),
          ),
        ),
      ),
    ],
  );

  prettyPrint(
    'Forward Message for Mediator wrapping the Encrypted Message for Bob',
    forwardMessageByAlice,
  );

  final signedMessageToForward = await SignedMessage.pack(
    forwardMessageByAlice,
    signer: aliceSigner,
  );

  prettyPrint('Singed Forward Message', signedMessageToForward);

  final bobMediatorJwks = bobMediatorDocument.keyAgreement.map((keyAgreement) {
    final jwk = keyAgreement.asJwk().toJson();
    // TODO: kid is not available in the Jwk anymore. clarify with the team
    jwk['kid'] = keyAgreement.id;

    return jwk;
  }).toList();

  final encryptedMessageToForward =
      await EncryptedMessage.packWithAuthentication(
    signedMessageToForward,
    wallet: aliceWallet,
    keyId: aliceKeyId,
    jwksPerRecipient: [
      Jwks.fromJson({
        'keys': bobMediatorJwks,
      }),
    ],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  prettyPrint('Encrypted Forward Message', encryptedMessageToForward);

  // Alice is going to use Bob's Mediator to send him a message

  final aliceMediatorClient = MediatorClient(
    mediatorDidDocument: bobMediatorDocument,
    wallet: aliceWallet,
    keyId: aliceKeyId,
    didSigner: aliceSigner,
  );

  // authenticate method is not direct part of mediatorClient, but it is extension method
  // this method is need for mediators, that require authentication like an Affinidi mediator
  final aliceTokens = await aliceMediatorClient.authenticate();

  final bobMediatorClient = MediatorClient(
    mediatorDidDocument: bobMediatorDocument,
    wallet: bobWallet,
    keyId: bobKeyId,
    didSigner: bobSigner,
  );

  final bobTokens = await bobMediatorClient.authenticate();

  print('Alice is sending a message...');

  await aliceMediatorClient.sendMessage(
    encryptedMessageToForward,
    accessToken: aliceTokens.accessToken,
  );

  print('Bob is fetching messages...');

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
      recipientWallet: bobWallet,
    );

    prettyPrint(
      'Unpacked Plain Text Message received by Bob via Mediator',
      originalPlainTextMessageFromAlice,
    );
  }
}
