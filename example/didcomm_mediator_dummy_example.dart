import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/encoding.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/encryption_algorithm.dart';
import 'package:didcomm/src/messages/attachments/attachment.dart';
import 'package:didcomm/src/messages/attachments/attachment_data.dart';
import 'package:didcomm/src/messages/didcomm_message.dart';
import 'package:didcomm/src/messages/protocols/routing/forward_message.dart';
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

  print('Alice DID: ${aliceDidDocument.id}');
  print('');

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

  print('Bob DID: ${bobDidDocument.id}');
  print('');

  // TODO: kid is not available in the Jwk anymore. clarify with the team
  final bobJwk = bobDidDocument.keyAgreement[0].asJwk().toJson();
  bobJwk['kid'] =
      '${bobDidDocument.id}#${bobDidDocument.id.replaceFirst('did:key:', '')}';

  // Important! link JWK, so the wallet should be able to find the key pair by JWK
  bobWallet.linkJwkKeyIdKeyWithKeyId(bobJwk['kid']!, bobKeyId);

  final mediatorDidDocument =
      await readDidDocument('./example/mediator/mediator_did_document.json');

  final plainTextMassage = PlainTextMessage(
    id: Uuid().v4(),
    from: aliceDidDocument.id,
    to: [bobDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': 'Hello, Bob!'},
  );

  plainTextMassage['custom-header'] = 'custom-value';

  print(jsonEncode(plainTextMassage));
  print('');

  final signedMessageByAlice = await SignedMessage.pack(
    plainTextMassage,
    signer: aliceSigner,
  );

  print(jsonEncode(signedMessageByAlice));
  print('');

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

  final aliceMediatorClient = MediatorClient(
    mediatorDidDocument: mediatorDidDocument,
    wallet: aliceWallet,
    keyId: aliceKeyId,
  );

  // authenticate method is not direct part of mediatorClient, but it is extension method
  // this method is need for mediators, that require authentication like an Affinidi mediator
  final aliceTokens = await aliceMediatorClient.authenticate(
    wallet: aliceWallet,
    keyId: aliceKeyId,
    mediatorDidDocument: mediatorDidDocument,
  );

  final bobMediatorClient = MediatorClient(
    mediatorDidDocument: mediatorDidDocument,
    wallet: bobWallet,
    keyId: bobKeyId,
  );

  final bobTokens = await bobMediatorClient.authenticate(
    wallet: bobWallet,
    keyId: bobKeyId,
    mediatorDidDocument: mediatorDidDocument,
  );

  print('Alice is sending a message...');

  await sendMessageToMediator(
      mediatorClient: aliceMediatorClient,
      wallet: aliceWallet,
      keyId: aliceKeyId,
      signer: aliceSigner,
      accessToken: aliceTokens.accessToken,
      recipientId: bobDidDocument.id,
      message: encryptedMessageByAlice);

  print('Bob is waiting for a message...');

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

    print(jsonEncode(originalPlainTextMessageFromAlice));
  }

  // await bobMediatorClient.listenForIncomingMessages(
  //   (message) async {
  //     print(jsonEncode(message));

  //     final unpackedMessageByBod =
  //         await DidcommMessage.unpackToPlainTextMessage(
  //       message: message,
  //       recipientWallet: bobWallet,
  //     );

  //     print(jsonEncode(unpackedMessageByBod));
  //     print('');

  //     await bobMediatorClient.disconnect();
  //   },
  //   onError: (error) => print(error),
  //   accessToken: bobTokens.accessToken,
  //   recipientWallet: bobWallet,
  //   recipientKeyId: bobKeyId,
  // );
}

Future<void> sendMessageToMediator({
  required MediatorClient mediatorClient,
  required Wallet wallet,
  required String keyId,
  required DidSigner signer,
  required String accessToken,
  required String recipientId,
  required EncryptedMessage message,
}) async {
  final createdTime = DateTime.now().toUtc();
  final expiresTime = createdTime.add(const Duration(seconds: 60));

  final forwardMessageByAlice = ForwardMessage(
    id: Uuid().v4(),
    to: [
      mediatorClient.mediatorDidDocument.id
    ], // NOTICE: here we can use DIDDocument from mediator instance
    next: recipientId,
    expiresTime: expiresTime,
    attachments: [
      Attachment(
        mediaType: 'application/json',
        data: AttachmentData(
          base64: base64UrlEncodeNoPadding(
            message.toJsonBytes(),
          ),
        ),
      ),
    ],
  );

  final signedMessageToForward = await SignedMessage.pack(
    forwardMessageByAlice,
    signer: signer,
  );

  // NOTICE: here we can use DIDDocument from mediator instance
  final mediatorJwks =
      mediatorClient.mediatorDidDocument.keyAgreement.map((keyAgreement) {
    final jwk = keyAgreement.asJwk().toJson();
    // TODO: kid is not available in the Jwk anymore. clarify with the team
    jwk['kid'] = keyAgreement.id;

    return jwk;
  }).toList();

  final encryptedMessageToForward =
      await EncryptedMessage.packWithAuthentication(
    signedMessageToForward,
    wallet: wallet,
    keyId: keyId,
    jwksPerRecipient: [
      Jwks.fromJson({
        'keys': mediatorJwks,
      }),
    ],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  await mediatorClient.sendMessage(
    encryptedMessageToForward,
    accessToken: accessToken,
  );
}
