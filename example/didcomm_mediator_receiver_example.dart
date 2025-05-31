import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/messages/didcomm_message.dart';
import 'package:ssi/ssi.dart';
import 'package:ssi/src/wallet/key_store/in_memory_key_store.dart';

import 'helpers.dart';

void main() async {
  // Run commands below in your terminal to generate keys for your receiver:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance with https://portal.affinidi.com. Copy its DID Document into example/mediator/mediator_did_document.json.

  final receiverKeyStore = InMemoryKeyStore();
  final receiverWallet = PersistentWallet(receiverKeyStore);

  final receiverKeyId = 'bob-key-1';
  final receiverPrivateKeyBytes =
      await extractPrivateKeyBytes('./example/keys/bob_private_key.pem');

  await receiverKeyStore.set(
    receiverKeyId,
    StoredKey.fromPrivateKey(
      keyType: KeyType.p256,
      keyBytes: receiverPrivateKeyBytes,
    ),
  );

  final receiverKeyPair = await receiverWallet.getKeyPair(receiverKeyId);
  final receiverDidDocument =
      DidKey.generateDocument(receiverKeyPair.publicKey);

  print('Receiver DID: ${receiverDidDocument.id}');
  print('');

  // TODO: kid is not available in the Jwk anymore. clarify with the team
  final receiverJwk = receiverDidDocument.keyAgreement[0].asJwk().toJson();
  receiverJwk['kid'] =
      '${receiverDidDocument.id}#${receiverDidDocument.id.replaceFirst('did:key:', '')}';

  // Important! link JWK, so the wallet should be able to find the key pair by JWK
  receiverWallet.linkJwkKeyIdKeyWithKeyId(receiverJwk['kid']!, receiverKeyId);

  final mediatorDidDocument =
      await readDidDocument('./example/mediator/mediator_did_document.json');

  final receiverMediatorClient = MediatorClient(
    mediatorDidDocument: mediatorDidDocument,
    wallet: receiverWallet,
    keyId: receiverKeyId,
  );

  final receiverTokens = await receiverMediatorClient.authenticate(
    wallet: receiverWallet,
    keyId: receiverKeyId,
    mediatorDidDocument: mediatorDidDocument,
  );

  print('Sender is receiving messages...');

  final messageIds = await receiverMediatorClient.listInboxMessageIds(
    accessToken: receiverTokens.accessToken,
  );

  final messages = await receiverMediatorClient.receiveMessages(
    messageIds: messageIds,
    accessToken: receiverTokens.accessToken,
  );

  if (messages.isEmpty) {
    print('No messages to read');
  }

  for (final message in messages) {
    final originalPlainTextMessageFromAlice =
        await DidcommMessage.unpackToPlainTextMessage(
      message: message,
      recipientWallet: receiverWallet,
    );

    print(jsonEncode(originalPlainTextMessageFromAlice));
  }
}
