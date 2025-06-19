import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/did_document_service_type.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/extensions/verification_method_list_extention.dart';
import 'package:ssi/ssi.dart';

import 'helpers.dart';

void main() async {
  // Run commands below in your terminal to generate keys for Receiver:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Create and run a DIDComm mediator, for instance with https://portal.affinidi.com.
  // Copy its DID Document URL into example/mediator/mediator_did.txt.

  final receiverKeyStore = InMemoryKeyStore();
  final receiverWallet = PersistentWallet(receiverKeyStore);

  final receiverKeyId = 'receiver-key-1';
  final receiverPrivateKeyBytes = await extractPrivateKeyBytes(
    './example/keys/bob_private_key.pem',
  );

  await receiverKeyStore.set(
    receiverKeyId,
    StoredKey(
      keyType: KeyType.p256,
      privateKeyBytes: receiverPrivateKeyBytes,
    ),
  );

  final receiverKeyPair = await receiverWallet.getKeyPair(receiverKeyId);
  final receiverDidDocument = DidKey.generateDocument(
    receiverKeyPair.publicKey,
  );

  await receiverDidDocument.copyServicesByTypeFromResolvedDid(
    DidDocumentServiceType.didCommMessaging,
    await readDid('./example/mediator/mediator_did.txt'),
  );

  // Serialized receiverMediatorDocument needs to shared with sender
  prettyPrint('Receiver DID Document', receiverDidDocument);

  final receiverMediatorDocument = await UniversalDIDResolver.resolve(
    receiverDidDocument.getFirstServiceDidByType(
      DidDocumentServiceType.didCommMessaging,
    )!,
  );

  final receiverSigner = DidSigner(
    didDocument: receiverDidDocument,
    keyPair: receiverKeyPair,
    didKeyId: receiverDidDocument.verificationMethod[0].id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final receiverJwks = receiverDidDocument.keyAgreement.toJwks();

  for (var jwk in receiverJwks.keys) {
    // Important! link JWK, so the wallet should be able to find the key pair by JWK
    // It will be replaced with DID Manager
    receiverWallet.linkDidKeyIdKeyWithKeyId(jwk.keyId!, receiverKeyId);
  }

  final receiverMediatorClient = MediatorClient(
    mediatorDidDocument: receiverMediatorDocument,
    keyPair: receiverKeyPair,
    didKeyId: receiverWallet.getDidIdByKeyId(receiverKeyId)!,
    signer: receiverSigner,
  );

  final receiverTokens = await receiverMediatorClient.authenticate();
  print('Receiver is fetching messages...');

  final messageIds = await receiverMediatorClient.listInboxMessageIds(
    accessToken: receiverTokens.accessToken,
  );

  final messages = await receiverMediatorClient.receiveMessages(
    messageIds: messageIds,
    accessToken: receiverTokens.accessToken,
  );

  for (final message in messages) {
    final originalPlainTextMessageFromSender =
        await DidcommMessage.unpackToPlainTextMessage(
      message: message,
      recipientWallet: receiverWallet,
    );

    prettyPrint(
      'Unpacked Plain Text Message received by Receiver via Mediator',
      originalPlainTextMessageFromSender,
    );
  }
}
