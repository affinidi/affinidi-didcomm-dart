import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/encoding.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/encryption_algorithm.dart';
import 'package:didcomm/src/messages/attachments/attachment.dart';
import 'package:didcomm/src/messages/attachments/attachment_data.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import 'helpers.dart';

void main() async {
  // Run commands below in your terminal to generate keys for your sender:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/alice_private_key.pem

  // Create and run a DIDComm mediator, for instance with https://portal.affinidi.com. Copy its DID Document into example/mediator/mediator_did_document.json.

  // Replace this DID Document with your receiver DID Document
  final receiverDidDocument = DidDocument.fromJson(jsonDecode("""
    {
      "id": "did:key:zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy",
      "@context": [
        "https://www.w3.org/ns/did/v1",
        "https://ns.did.ai/suites/multikey-2021/v1/"
      ],
      "verificationMethod": [
        {
          "id": "did:key:zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy#zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy",
          "controller": "did:key:zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy",
          "type": "P256Key2021",
          "publicKeyMultibase": "zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy"
        }
      ],
      "authentication": [
        "did:key:zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy#zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy"
      ],
      "capabilityDelegation": [
        "did:key:zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy#zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy"
      ],
      "capabilityInvocation": [
        "did:key:zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy#zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy"
      ],
      "keyAgreement": [
        "did:key:zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy#zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy"
      ],
      "assertionMethod": [
        "did:key:zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy#zDnaemfWXqUu9bSWWEAVb4KNfbPC1Ca5AftrkiuDeUDdw1eMy"
      ]
    }
  """));

  final messageForReceiver = 'Hello, Bob!';

  final receiverJwks = receiverDidDocument.keyAgreement.map((keyAgreement) {
    final jwk = keyAgreement.asJwk().toJson();
    // TODO: kid is not available in the Jwk anymore. clarify with the team
    jwk['kid'] = keyAgreement.id;

    return jwk;
  }).toList();

  final senderKeyStore = InMemoryKeyStore();
  final senderWallet = PersistentWallet(senderKeyStore);

  final senderKeyId = 'alice-key-1';
  final senderPrivateKeyBytes =
      await extractPrivateKeyBytes('./example/keys/alice_private_key.pem');

  await senderKeyStore.set(
    senderKeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: senderPrivateKeyBytes,
    ),
  );

  final senderKeyPair = await senderWallet.getKeyPair(senderKeyId);
  final senderDidDocument = DidKey.generateDocument(senderKeyPair.publicKey);

  print('Sender DID: ${senderDidDocument.id}');
  print('');

  final senderSigner = DidSigner(
    didDocument: senderDidDocument,
    keyPair: senderKeyPair,
    didKeyId: senderDidDocument.verificationMethod[0].id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final mediatorDidDocument =
      await readDidDocument('./example/mediator/mediator_did_document.json');

  final plainTextMassage = PlainTextMessage(
    id: Uuid().v4(),
    from: senderDidDocument.id,
    to: [receiverDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': messageForReceiver},
  );

  plainTextMassage['custom-header'] = 'custom-value';

  print(jsonEncode(plainTextMassage));
  print('');

  final signedMessageByAlice = await SignedMessage.pack(
    plainTextMassage,
    signer: senderSigner,
  );

  print(jsonEncode(signedMessageByAlice));
  print('');

  final encryptedMessageByAlice = await EncryptedMessage.packWithAuthentication(
    signedMessageByAlice,
    wallet: senderWallet,
    keyId: senderKeyId,
    jwksPerRecipient: [
      Jwks.fromJson({
        'keys': receiverJwks,
      }),
    ],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  final createdTime = DateTime.now().toUtc();
  final expiresTime = createdTime.add(const Duration(seconds: 60));

  final forwardMessageByAlice = ForwardMessage(
    id: Uuid().v4(),
    to: [mediatorDidDocument.id],
    next: receiverDidDocument.id,
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

  print(jsonEncode(forwardMessageByAlice));
  print('');

  final signedMessageToForward = await SignedMessage.pack(
    forwardMessageByAlice,
    signer: senderSigner,
  );

  print(jsonEncode(signedMessageToForward));
  print('');

  final mediatorJwks = mediatorDidDocument.keyAgreement.map((keyAgreement) {
    final jwk = keyAgreement.asJwk().toJson();
    // TODO: kid is not available in the Jwk anymore. clarify with the team
    jwk['kid'] = keyAgreement.id;

    return jwk;
  }).toList();

  final encryptedMessageToForward =
      await EncryptedMessage.packWithAuthentication(
    signedMessageToForward,
    wallet: senderWallet,
    keyId: senderKeyId,
    jwksPerRecipient: [
      Jwks.fromJson({
        'keys': mediatorJwks,
      }),
    ],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  print(jsonEncode(encryptedMessageToForward));
  print('');

  final aliceMediatorClient = MediatorClient(
    mediatorDidDocument: mediatorDidDocument,
    wallet: senderWallet,
    keyId: senderKeyId,
    didSigner: senderSigner,
  );

  // authenticate method is not direct part of mediatorClient, but it is extension method
  // this method is need for mediators, that require authentication like an Affinidi mediator
  final aliceTokens = await aliceMediatorClient.authenticate();

  await aliceMediatorClient.sendMessage(
    encryptedMessageToForward,
    accessToken: aliceTokens.accessToken,
  );

  print('The message has been sent');
}
