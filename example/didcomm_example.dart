import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/encryption_algorithm.dart';
import 'package:didcomm/src/messages/didcomm_message.dart';
import 'package:ssi/ssi.dart';
import 'package:ssi/src/wallet/key_store/in_memory_key_store.dart';

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

  final bobKeyId = 'bob-key-1';
  final bobKeyPair = await bobWallet.generateKey(
    keyId: bobKeyId,
    keyType: KeyType.p256,
  );

  final bobDidDocument = DidKey.generateDocument(bobKeyPair.publicKey);

  // TODO: kid is not available in the Jwk anymore. clarify with the team
  final bobJwk = bobDidDocument.keyAgreement[0].asJwk().toJson();
  bobJwk['kid'] =
      '${bobDidDocument.id}#${bobDidDocument.id.replaceFirst('did:key:', '')}';

  // Important! link JWK, so the wallet should be able to find the key pair by JWK
  bobWallet.linkJwkKeyIdKeyWithKeyId(bobJwk['kid']!, bobKeyId);

  final plainTextMassage = PlainTextMessage(
    id: '041b47d4-9c8f-4a24-ae85-b60ec91b025c',
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

  final sentMessageByAlice = jsonEncode(encryptedMessageByAlice);
  print(sentMessageByAlice);
  print('');

  final unpackedMessageByBod = await DidcommMessage.unpackToPlainTextMessage(
    message: jsonDecode(sentMessageByAlice),
    recipientWallet: bobWallet,
  );

  print(unpackedMessageByBod?.toJson());
  print('');
}
