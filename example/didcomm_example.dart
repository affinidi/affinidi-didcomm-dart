import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/extensions/verification_method_list_extention.dart';
import 'package:ssi/ssi.dart';

import 'helpers.dart';

void main() async {
  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);

  final aliceKeyId = 'alice-key-1';
  final aliceKeyPair = await aliceWallet.generateKey(
    keyId: aliceKeyId,
    keyType: KeyType.p256,
  );

  final aliceDidDocument = DidKey.generateDocument(aliceKeyPair.publicKey);

  final aliceSigner = DidSigner(
    didDocument: aliceDidDocument,
    keyPair: aliceKeyPair,
    didKeyId: aliceDidDocument.verificationMethod[0].id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final aliceJwks = aliceDidDocument.keyAgreement.toJwks();

  for (var jwk in aliceJwks.keys) {
    // Important! link JWK, so the wallet should be able to find the key pair by JWK
    // It will be replaced with DID Manager
    aliceWallet.linkJwkKeyIdKeyWithKeyId(jwk.keyId!, aliceKeyId);
  }

  final bobKeyId = 'bob-key-1';
  final bobKeyPair = await bobWallet.generateKey(
    keyId: bobKeyId,
    keyType: KeyType.p256,
  );

  final bobDidDocument = DidKey.generateDocument(bobKeyPair.publicKey);
  final bobJwks = bobDidDocument.keyAgreement.toJwks();

  for (var jwk in bobJwks.keys) {
    // Important! link JWK, so the wallet should be able to find the key pair by JWK
    // It will be replaced with DID Manager
    bobWallet.linkJwkKeyIdKeyWithKeyId(jwk.keyId!, bobKeyId);
  }

  final alicePlainTextMassage = PlainTextMessage(
    id: '041b47d4-9c8f-4a24-ae85-b60ec91b025c',
    from: aliceDidDocument.id,
    to: [bobDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': 'Hello, Bob!'},
  );

  alicePlainTextMassage['custom-header'] = 'custom-value';
  prettyPrint('Plain Text Message for Bob', alicePlainTextMassage);

  final aliceSignedMessage = await SignedMessage.pack(
    alicePlainTextMassage,
    signer: aliceSigner,
  );

  prettyPrint(
    'Signed Message by Alice',
    aliceSignedMessage,
  );

  // find keys whose curve is common in other DID Documents
  final aliceMatchedKeyIds = aliceDidDocument.getKeyIdsWithCommonType(
    wallet: aliceWallet,
    otherDidDocuments: [
      bobDidDocument,
    ],
  );

  final aliceEncryptedMessage = await EncryptedMessage.packWithAuthentication(
    aliceSignedMessage,
    keyPair: await aliceWallet.generateKey(
      keyId: aliceMatchedKeyIds.first,
    ),
    jwksPerRecipient: [
      bobJwks,
    ],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  prettyPrint(
    'Encrypted Message by Alice',
    aliceEncryptedMessage,
  );

  final sentMessageByAlice = jsonEncode(aliceEncryptedMessage);

  final unpackedMessageByBob = await DidcommMessage.unpackToPlainTextMessage(
    message: jsonDecode(sentMessageByAlice),
    recipientWallet: bobWallet,
  );

  prettyPrint(
    'Unpacked Plain Text Message received by Bob',
    unpackedMessageByBob,
  );
}
