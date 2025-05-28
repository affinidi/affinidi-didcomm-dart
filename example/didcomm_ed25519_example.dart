import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/encryption_algorithm.dart';
import 'package:didcomm/src/messages/didcomm_message.dart';
import 'package:ssi/ssi.dart';
import 'package:ssi/src/wallet/key_store/in_memory_key_store.dart';
import 'package:convert/convert.dart';

void main() async {
  final aliceSeed = hex.decode(
    'a1772b144344781f2a55fc4d5e49f3767bb0967205ad08454a09c76d96fd2ccd',
  );

  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = await Bip32Ed25519Wallet.fromSeed(
    Uint8List.fromList(aliceSeed),
    aliceKeyStore,
  );

  final bobSeed = hex.decode(
    'b2883c25545589203b66fc5e6f5a04878cc1078311be19525b10d87897fe3ddf',
  );

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = await Bip32Ed25519Wallet.fromSeed(
    Uint8List.fromList(bobSeed),
    bobKeyStore,
  );

  final aliceKeyId = 'alice-key-1';
  final aliceKeyPair = await aliceWallet.deriveKey(
    keyId: aliceKeyId,
    keyType: KeyType.ed25519,
    derivationPath: "m/44'/60'/0'/0'/0'",
  );

  final aliceX25519PublicKey = await aliceWallet.getX25519PublicKey(
    aliceKeyPair.id,
  );

  final aliceDidDocument = DidKey.generateDocument(
    PublicKey(aliceKeyId, aliceX25519PublicKey, KeyType.x25519),
  );

  final aliceSigner = DidSigner(
    didDocument: aliceDidDocument,
    keyPair: aliceKeyPair,
    didKeyId: aliceDidDocument.verificationMethod[0].id,
    signatureScheme: SignatureScheme.eddsa_sha512,
  );

  final bobKeyId = 'bob-key-1';
  final bobKeyPair = await bobWallet.deriveKey(
    keyId: bobKeyId,
    keyType: KeyType.ed25519,
    derivationPath: "m/44'/60'/0'/0'/0'",
  );

  final bobX25519PublicKey = await bobWallet.getX25519PublicKey(bobKeyPair.id);

  final bobDidDocument = DidKey.generateDocument(
    PublicKey(bobKeyId, bobX25519PublicKey, KeyType.x25519),
  );

  // TODO: kid is not available in the Jwk anymore. clarify with the team
  final bobJwk = bobDidDocument.keyAgreement[0].asJwk().toJson();
  bobJwk['kid'] = '${bobDidDocument.id}#$bobKeyId';

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

  print(unpackedMessageByBod.toJson());
  print('');
}
