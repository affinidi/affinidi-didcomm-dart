import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/common/encoding.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/encryption_algorithm.dart';
import 'package:didcomm/src/messages/attachments/attachment.dart';
import 'package:didcomm/src/messages/attachments/attachment_data.dart';
import 'package:didcomm/src/messages/protocols/routing/forward_message.dart';
import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/primitives/asn1_octet_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:ssi/ssi.dart';
import 'package:ssi/src/wallet/key_store/in_memory_key_store.dart';

void main() async {
  // Run commands below in your terminal to generate keys for Alice and Bob:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/alice_private_key.pem
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem

  // Run the example and copy Alice and Bob DIDs from the terminal into mediator configuration, so it can authenticate their requests.

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
    StoredKey.fromPrivateKey(
      keyType: KeyType.p256,
      keyBytes: alicePrivateKeyBytes,
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
    StoredKey.fromPrivateKey(
      keyType: KeyType.p256,
      keyBytes: bobPrivateKeyBytes,
    ),
  );

  final bobKeyPair = await bobWallet.getKeyPair(bobKeyId);
  final bobDidDocument = DidKey.generateDocument(bobKeyPair.publicKey);

  print('Bob DID: ${bobDidDocument.id}');
  print('');

  // TODO: kid is not available in the Jwk anymore. clarify with the team
  final bobJwk = bobDidDocument.keyAgreement[0].asJwk().toJson();
  bobJwk['kid'] = '${bobDidDocument.id}#$bobKeyId';

  final mediatorDidDocument =
      await readDidDocument('./example/mediator/mediator_did_document.json');

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

  final createdTime = DateTime.now().toUtc();
  final expiresTime = createdTime.add(const Duration(seconds: 60));

  final forwardMessageByAlice = ForwardMessage(
    id: '48e09528-5495-4259-be68-d975e81671c3',
    to: [mediatorDidDocument.id],
    next: bobDidDocument.id,
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

  forwardMessageByAlice['ephemeral'] = true;

  print(jsonEncode(forwardMessageByAlice));
  print('');

  final signedMessageToForward = await SignedMessage.pack(
    forwardMessageByAlice,
    signer: aliceSigner,
  );

  final mediatorJwks = mediatorDidDocument.keyAgreement.map((keyAgreement) {
    final jwk = keyAgreement.asJwk().toJson();
    // TODO: kid is not available in the Jwk anymore. clarify with the team
    jwk['kid'] = keyAgreement.id;

    return jwk;
  }).toList();

  final encryptedMessageToForward =
      await EncryptedMessage.packWithAuthentication(
    signedMessageToForward,
    wallet: aliceWallet,
    keyId: aliceKeyId,
    jwksPerRecipient: [
      Jwks.fromJson({
        'keys': mediatorJwks,
      }),
    ],
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  );

  print(jsonEncode(encryptedMessageToForward));
  print('');

  final mediatorClient = MediatorClient(didDocument: mediatorDidDocument);

  // authenticate method is not direct part of mediatorClient, but it is extension method
  // this method is need for mediators, that require authentication like an Affinidi mediator
  final tokens = await mediatorClient.authenticate(
    senderWallet: aliceWallet,
    senderKeyId: aliceKeyId,
    mediatorDidDocument: mediatorDidDocument,
  );

  try {
    await mediatorClient.send(
      message: encryptedMessageToForward,
      accessToken: tokens.accessToken,
    );
  } catch (error) {
    throw error;
  }

  // final unpackedMessageByBod = await DidcommMessage.unpackToPlainTextMessage(
  //   message: jsonDecode(sentMessageByAlice),
  //   recipientWallet: bobWallet,
  // );

  // print(unpackedMessageByBod.toJson());
  // print('');
}

Future<Uint8List> extractPrivateKeyBytes(String pemPath) async {
  final pem = await File(pemPath).readAsString();

  final lines = pem.split('\n');
  final base64Str = lines
      .where((line) => !line.startsWith('-----') && line.trim().isNotEmpty)
      .join('');

  final derBytes = base64.decode(base64Str);

  final asn1Parser = ASN1Parser(derBytes);
  final sequence = asn1Parser.nextObject() as ASN1Sequence;

  final privateKeyOctetString = sequence.elements![1] as ASN1OctetString;
  return privateKeyOctetString.valueBytes!;
}

Future<DidDocument> readDidDocument(String didDocumentPath) async {
  final json = await File(didDocumentPath).readAsString();
  return DidDocument.fromJson(jsonDecode(json));
}
