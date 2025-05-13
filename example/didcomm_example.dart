import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/messages/attachments/attachment.dart';
import 'package:didcomm/src/messages/attachments/attachment_data.dart';
import 'package:ssi/ssi.dart';
import 'package:ssi/src/wallet/key_store/in_memory_key_store.dart';

void main() async {
  // --------------------------------------------------------------------
  // Alice creates a message fro Bob. The message is signed and encrypted
  // --------------------------------------------------------------------

  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);

  // final aliceKeyPair = await aliceWallet.generateKey();
  final bobKeyPair = await bobWallet.generateKey();

  // final aliceDidDoc = DidKey.generateDocument(aliceKeyPair.publicKey);
  final bobDidDoc = DidKey.generateDocument(bobKeyPair.publicKey);

  // final aliceSigner = DidSigner(
  //   didDocument: aliceDidDoc,
  //   keyPair: aliceKeyPair,
  //   didKeyId: aliceDidDoc.verificationMethod[0].id,
  //   signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  // );

  final plainTextMessage = PlaintextMessage(
    id: '123',
    from: 'did:example:123',
    to: ['did:example:456'],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    threadId: 'thread-123',
    parentThreadId: 'parent-thread-123',
    createdTime: DateTime.now(),
    expiresTime: DateTime.now().add(Duration(days: 1)),
    body: {'key': 'value'},
    attachments: [
      Attachment(
        id: 'attachment-1',
        data: AttachmentData(base64: 'base64data'),
      ),
    ],
  );

  final signedMessage = SignedMessage.fromPlainTextMessage(
    plainTextMessage,
    wallet: aliceWallet,
    walletKeyId: 'key-1',
  );

  final encryptedMessage = EncryptedMessage.fromMessage(
    signedMessage,
    wallet: bobWallet,
    walletKeyId: 'key-2',
    recipientPublicKeyJwks: [bobDidDoc.keyAgreement[0].asJwk()],
  );

  // final wrappedByMediatorMessage = ForwardMessage.fromMessage(encryptedMessage);

  // --------------------------------------------------------------------
  // Bob decrypts message and verifies signature
  // --------------------------------------------------------------------
}
