import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import 'helpers.dart';

void main() async {
  final aliceSeed = hex.decode(
    'a1772b144344781f2a55fc4d5e49f3767bb0967205ad08454a09c76d96fd2ccd',
  );

  final aliceWallet = Bip32Ed25519Wallet.fromSeed(
    Uint8List.fromList(aliceSeed),
  );

  final bobSeed = hex.decode(
    'b2883c25545589203b66fc5e6f5a04878cc1078311be19525b10d87897fe3ddf',
  );

  final bobWallet = Bip32Ed25519Wallet.fromSeed(
    Uint8List.fromList(bobSeed),
  );

  final aliceKeyId = "m/44'/60'/0'/0'/0'";
  final aliceDidManager = DidKeyManager(
    wallet: aliceWallet,
    store: InMemoryDidStore(),
  );

  await aliceWallet.generateKey(
    keyId: aliceKeyId,
    keyType: KeyType.ed25519,
  );

  await aliceDidManager.addVerificationMethod(aliceKeyId);
  final aliceDidDocument = await aliceDidManager.getDidDocument();

  final aliceSigner = await aliceDidManager.getSigner(
    aliceDidDocument.assertionMethod.first.id,
    signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final bobKeyId = "m/44'/60'/0'/0'/0'";
  final bobDidManager = DidKeyManager(
    wallet: bobWallet,
    store: InMemoryDidStore(),
  );

  await bobWallet.generateKey(
    keyId: bobKeyId,
    keyType: KeyType.ed25519,
  );

  await bobDidManager.addVerificationMethod(bobKeyId);
  final bobDidDocument = await bobDidManager.getDidDocument();

  final alicePlainTextMassage = PlainTextMessage(
    id: '041b47d4-9c8f-4a24-ae85-b60ec91b025c',
    from: aliceDidDocument.id,
    to: [bobDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': 'Hello, Bob!'},
  );

  alicePlainTextMassage['custom-header'] = 'custom-value';

  prettyPrint(
    'Plain Text Message for Bob',
    object: alicePlainTextMassage,
  );

  final aliceSignedMessage = await SignedMessage.pack(
    alicePlainTextMassage,
    signer: aliceSigner,
  );

  prettyPrint(
    'Signed Message by Alice',
    object: aliceSignedMessage,
  );

  // find keys whose curve is common in other DID Documents
  final aliceMatchedKeyIds = aliceDidDocument.matchKeysInKeyAgreement(
    otherDidDocuments: [bobDidDocument],
  );

  final aliceEncryptedMessage = await EncryptedMessage.packWithAuthentication(
    aliceSignedMessage,
    keyPair: await aliceDidManager.getKeyPairByDidKeyId(
      aliceMatchedKeyIds.first,
    ),
    didKeyId: aliceMatchedKeyIds.first,
    recipientDidDocuments: [bobDidDocument],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  prettyPrint(
    'Encrypted Message by Alice',
    object: aliceEncryptedMessage,
  );

  final sentMessageByAlice = jsonEncode(aliceEncryptedMessage);

  final unpackedMessageByBob = await DidcommMessage.unpackToPlainTextMessage(
    message: jsonDecode(sentMessageByAlice) as Map<String, dynamic>,
    recipientDidManager: bobDidManager,
    expectedMessageWrappingTypes: [
      MessageWrappingType.authcryptSignPlaintext,
    ],
    expectedSigners: [
      aliceDidDocument.assertionMethod.first.id,
    ],
  );

  prettyPrint(
    'Unpacked Plain Text Message received by Bob',
    object: unpackedMessageByBob,
  );
}
