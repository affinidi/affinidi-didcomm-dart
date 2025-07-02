import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/create_message_assertion.dart';

void main() async {
  group('Encrypted message', () {
    final aliceKeyStore = InMemoryKeyStore();
    final aliceWallet = PersistentWallet(aliceKeyStore);

    group('Persisted wallet', () {
      for (final keyType in [
        KeyType.p256,
      ]) {
        for (final signatureScheme in [
          SignatureScheme.ecdsa_p256_sha256,
        ]) {
          group(keyType.name, () {
            final aliceKeyId = 'alice-key-1-${keyType.name}';

            late DidController aliceDidController;
            late DidDocument aliceDidDocument;
            late DidSigner aliceSigner;

            setUp(() async {
              aliceDidController = DidKeyController(
                wallet: aliceWallet,
                store: InMemoryDidStore(),
              );

              await aliceWallet.generateKey(
                keyId: aliceKeyId,
                keyType: keyType,
              );

              await aliceDidController.addVerificationMethod(aliceKeyId);
              aliceDidDocument = await aliceDidController.getDidDocument();

              aliceSigner = await aliceDidController.getSigner(
                aliceDidDocument.assertionMethod.first.id,
                signatureScheme: signatureScheme,
              );
            });

            test('Pack and unpack encrypted message successfully', () async {
              // Act: create and sign the message
              const content = 'Hello, Bob!';
              final plainTextMessage =
                  MessageAssertionService.createPlainTextMessageAssertion(
                content,
                from: aliceDidDocument.id,
                to: ['did:rand:0x1234567890abcdef1234567890abcdef12345678'],
              );

              final signedMessage = await SignedMessage.pack(
                plainTextMessage,
                signer: aliceSigner,
              );

              expect(signedMessage.signatures, isNotNull);
              expect(
                signedMessage.signatures[0].header.keyId,
                aliceSigner.keyId,
              );

              final unpackedPlainTextMessage =
                  await DidcommMessage.unpackToPlainTextMessage(
                message: signedMessage.toJson(),
                recipientDidController: aliceDidController,
                validateAddressingConsistency: true,
                expectedMessageWrappingTypes: [
                  MessageWrappingType.signedPlaintext,
                ],
                expectedSigners: [
                  aliceSigner.didKeyId,
                ],
              );

              expect(unpackedPlainTextMessage, isNotNull);
              expect(unpackedPlainTextMessage.body!['content'], content);
            });
          });
        }
      }
    });
  });
}
