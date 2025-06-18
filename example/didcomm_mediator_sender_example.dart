import 'dart:convert';

import 'package:didcomm/didcomm.dart';
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
  // Run commands below in your terminal to generate keys for Receiver:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance with https://portal.affinidi.com.
  // Copy its DID Document URL into example/mediator/mediator_did.txt.

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
  final receiverJwks = receiverDidDocument.keyAgreement.toJwks();

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

  prettyPrint('Sender DID', senderDidDocument.id);

  final senderSigner = DidSigner(
    didDocument: senderDidDocument,
    keyPair: senderKeyPair,
    didKeyId: senderDidDocument.verificationMethod[0].id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final receiverMediatorDidDocument =
      await readDidDocument('./example/mediator/mediator_did_document.json');

  final senderPlainTextMassage = PlainTextMessage(
    id: Uuid().v4(),
    from: senderDidDocument.id,
    to: [receiverDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': messageForReceiver},
  );

  senderPlainTextMassage['custom-header'] = 'custom-value';
  prettyPrint('Plain Text Message for Receiver', senderPlainTextMassage);

  // find keys whose curve is common in other DID Documents
  final aliceMatchedKeyIds = senderDidDocument.getKeyIdsWithCommonType(
    wallet: senderWallet,
    otherDidDocuments: [
      receiverDidDocument,
    ],
  );

  final senderSignedAndEncryptedMessage =
      await DidcommMessage.packIntoSignedAndEncryptedMessages(
    senderPlainTextMassage,
    wallet: senderWallet,
    keyId: aliceMatchedKeyIds.first,
    jwksPerRecipient: [receiverJwks],
    keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    signer: senderSigner,
  );

  prettyPrint(
    'Encrypted and Signed Message by Sender',
    senderSignedAndEncryptedMessage,
  );

  final createdTime = DateTime.now().toUtc();
  final expiresTime = createdTime.add(const Duration(seconds: 60));

  final forwardMessage = ForwardMessage(
    id: Uuid().v4(),
    to: [receiverMediatorDidDocument.id],
    next: receiverDidDocument.id,
    expiresTime: expiresTime,
    attachments: [
      Attachment(
        mediaType: 'application/json',
        data: AttachmentData(
          base64: base64UrlEncodeNoPadding(
            senderSignedAndEncryptedMessage.toJsonBytes(),
          ),
        ),
      ),
    ],
  );

  prettyPrint(
    'Forward Message for Mediator that wraps Encrypted Message for Receiver',
    forwardMessage,
  );

  final senderMediatorClient = MediatorClient(
    mediatorDidDocument: receiverMediatorDidDocument,
    wallet: senderWallet,
    keyId: senderKeyId,
    signer: senderSigner,
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
  final aliceTokens = await senderMediatorClient.authenticate();

  await senderMediatorClient.sendMessage(
    forwardMessage,
    accessToken: aliceTokens.accessToken,
  );

  print('The message has been sent');
}
