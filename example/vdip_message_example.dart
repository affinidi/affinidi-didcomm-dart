import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

// This example mirrors didcomm_example.dart but uses a VDIP message
// (request issuance) instead of a generic PlainTextMessage, showing
// how you can still sign, encrypt, send, decrypt, and then differentiate
// VDIP messages by their type URI.
void main() async {
  // Holder (Alice) setup
  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);
  final aliceDidManager = DidKeyManager(
    wallet: aliceWallet,
    store: InMemoryDidStore(),
  );

  // Issuer (Bob) setup
  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);
  final bobDidManager = DidKeyManager(
    wallet: bobWallet,
    store: InMemoryDidStore(),
  );

  // Generate keys & DIDs
  const aliceKeyId = 'alice-vdip-key-1';
  await aliceWallet.generateKey(keyId: aliceKeyId, keyType: KeyType.p256);
  await aliceDidManager.addVerificationMethod(aliceKeyId);
  final aliceDidDocument = await aliceDidManager.getDidDocument();

  const bobKeyId = 'bob-vdip-key-1';
  await bobWallet.generateKey(keyId: bobKeyId, keyType: KeyType.p256);
  await bobDidManager.addVerificationMethod(bobKeyId);
  final bobDidDocument = await bobDidManager.getDidDocument();

  // Signer for Alice
  final aliceSigner = await aliceDidManager.getSigner(
    aliceDidDocument.assertionMethod.first.id,
  );

  // Create a VDIP Request Issuance message (instead of generic PlainTextMessage)
  final requestIssuanceMessage = VdipMessage.requestIssuanceMessage(
    id: '9e6b1ab9-6a3d-4f9d-94ee-f2d6a1111111',
    from: aliceDidDocument.id,
    to: [bobDidDocument.id],
    createdTime: DateTime.now().toUtc(),
    expiresTime: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    body: {
      'credential_type': 'VerifiableId',
      'format': 'jwt_vc',
      'claims': {
        'firstName': 'Alice',
        'lastName': 'Example',
      },
    },
  );

  // Add a custom header (same as didcomm_example pattern)
  requestIssuanceMessage['custom-header'] = 'custom-value';

  prettyPrint('VDIP Request Issuance Message (Alice -> Bob)',
      object: requestIssuanceMessage);

  // Sign
  final signedMessage = await SignedMessage.pack(
    requestIssuanceMessage,
    signer: aliceSigner,
  );
  prettyPrint('Signed VDIP Message by Alice', object: signedMessage);

  // Find compatible key(s) for authenticated encryption
  final aliceMatchedKeyIds = aliceDidDocument.matchKeysInKeyAgreement(
    otherDidDocuments: [bobDidDocument],
  );

  // Encrypt with authentication (authcrypt + sign + plaintext)
  final encryptedMessage = await EncryptedMessage.packWithAuthentication(
    signedMessage,
    keyPair:
        await aliceDidManager.getKeyPairByDidKeyId(aliceMatchedKeyIds.first),
    didKeyId: aliceMatchedKeyIds.first,
    recipientDidDocuments: [bobDidDocument],
  );
  prettyPrint('Encrypted VDIP Message by Alice', object: encryptedMessage);

  // Simulate sending (serialize) & receiving (deserialize)
  final transmittedJson = jsonEncode(encryptedMessage);

  // Bob unpacks to a PlainTextMessage representation
  final unpackedPlain = await DidcommMessage.unpackToPlainTextMessage(
    message: jsonDecode(transmittedJson) as Map<String, dynamic>,
    recipientDidManager: bobDidManager,
    expectedMessageWrappingTypes: [
      MessageWrappingType.authcryptSignPlaintext,
    ],
    expectedSigners: [
      aliceDidDocument.assertionMethod.first.didKeyId,
    ],
  );

  prettyPrint('Unpacked VDIP Plain Text Message (Bob received)',
      object: unpackedPlain);

  // Differentiate VDIP message type via its type URI
  final isRequestIssuance =
      unpackedPlain.type == VdipMessage.requestIssuanceMessageUri;
  final isIdentificationRequest =
      unpackedPlain.type == VdipMessage.identificationRequestMessageUri;
  final isIssuedCredential =
      unpackedPlain.type == VdipMessage.issuedCredentialMessageUri;
  final isAcceptedCredential =
      unpackedPlain.type == VdipMessage.acceptedCredentialMessageUri;
  final isProblemReport =
      unpackedPlain.type == VdipMessage.problemReportMessageUri;

  prettyPrint('VDIP Message Type Detection', object: {
    'isRequestIssuance': isRequestIssuance,
    'isIdentificationRequest': isIdentificationRequest,
    'isIssuedCredential': isIssuedCredential,
    'isAcceptedCredential': isAcceptedCredential,
    'isProblemReport': isProblemReport,
  });
}
