import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:ssi/ssi.dart';
import 'package:convert/convert.dart';

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
  final aliceKeyPair = await aliceWallet.generateKey(
    keyId: aliceKeyId,
    keyType: KeyType.ed25519,
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

  for (var keyAgreement in aliceDidDocument.keyAgreement) {
    // Important! link JWK, so the wallet should be able to find the key pair by JWK
    // It will be replaced with DID Manager
    aliceWallet.linkDidKeyIdKeyWithKeyId(keyAgreement.id, aliceKeyId);
  }

  final bobKeyId = "m/44'/60'/0'/0'/0'";
  final bobKeyPair = await bobWallet.generateKey(
    keyId: bobKeyId,
    keyType: KeyType.ed25519,
  );

  final bobX25519PublicKey = await bobWallet.getX25519PublicKey(bobKeyPair.id);

  final bobDidDocument = DidKey.generateDocument(
    PublicKey(bobKeyId, bobX25519PublicKey, KeyType.x25519),
  );

  for (var keyAgreement in bobDidDocument.keyAgreement) {
    // Important! link JWK, so the wallet should be able to find the key pair by JWK
    // It will be replaced with DID Manager
    bobWallet.linkDidKeyIdKeyWithKeyId(keyAgreement.id, bobKeyId);
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
    didKeyId: aliceWallet.getDidIdByKeyId(aliceMatchedKeyIds.first)!,
    recipientDidDocuments: [bobDidDocument],
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
