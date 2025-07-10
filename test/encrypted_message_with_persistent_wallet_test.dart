import 'dart:convert';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/create_message_assertion.dart';

void main() async {
  group('Encrypted message', () {
    final aliceKeyStore = InMemoryKeyStore();
    final aliceWallet = PersistentWallet(aliceKeyStore);

    final bobKeyStore = InMemoryKeyStore();
    final bobWallet = PersistentWallet(bobKeyStore);
    group('Persisted wallet', () {
      for (final keyType in [
        KeyType.p256,
        // TODO: Uncomment when supported by Dart SSI
        // KeyType.p384,
        // KeyType.p521,
      ]) {
        group(keyType.name, () {
          final aliceKeyId = 'alice-key-1-${keyType.name}';
          final bobKeyId = 'bob-key-1-${keyType.name}';

          late DidManager aliceDidManager;
          late DidManager bobDidManager;
          late DidDocument aliceDidDocument;
          late DidDocument bobDidDocument;
          late DidSigner aliceSigner;

          setUp(() async {
            aliceDidManager = DidKeyManager(
              wallet: aliceWallet,
              store: InMemoryDidStore(),
            );

            bobDidManager = DidKeyManager(
              wallet: bobWallet,
              store: InMemoryDidStore(),
            );

            await aliceWallet.generateKey(
              keyId: aliceKeyId,
              keyType: keyType,
            );

            await aliceDidManager.addVerificationMethod(aliceKeyId);
            aliceDidDocument = await aliceDidManager.getDidDocument();

            aliceSigner = await aliceDidManager.getSigner(
              aliceDidDocument.assertionMethod.first.id,
            );

            await bobWallet.generateKey(
              keyId: bobKeyId,
              keyType: keyType,
            );

            await bobDidManager.addVerificationMethod(bobKeyId);
            bobDidDocument = await bobDidManager.getDidDocument();
          });

          for (final encryptionAlgorithm in [
            EncryptionAlgorithm.a256cbc,
            EncryptionAlgorithm.a256gcm
          ]) {
            group(encryptionAlgorithm.value, () {
              for (final isAuthenticated in [true, false]) {
                group(isAuthenticated ? 'Authenticated' : 'Anonymous', () {
                  test(
                    'Pack and unpack encrypted message successfully',
                    () async {
                      // Act: create, sign, and encrypt the message
                      const content = 'Hello, Bob!';
                      final plainTextMessage = MessageAssertionService
                          .createPlainTextMessageAssertion(
                        content,
                        from: aliceDidDocument.id,
                        to: [bobDidDocument.id],
                      );

                      final signedMessage = await SignedMessage.pack(
                        plainTextMessage,
                        signer: aliceSigner,
                      );

                      // find keys whose curve is common in other DID Documents
                      final aliceMatchedDidKeyIds =
                          aliceDidDocument.matchKeysInKeyAgreement(
                        otherDidDocuments: [
                          bobDidDocument,
                        ],
                      );

                      final sut = await EncryptedMessage.pack(
                        signedMessage,
                        keyPair: isAuthenticated
                            ? await aliceDidManager.getKeyPairByDidKeyId(
                                aliceMatchedDidKeyIds.first,
                              )
                            : null,
                        didKeyId: isAuthenticated
                            ? aliceMatchedDidKeyIds.first
                            : null,
                        keyType: isAuthenticated
                            ? null
                            : [
                                bobDidDocument
                                // other recipients here
                              ].getCommonKeyTypesInKeyAgreements().first,
                        recipientDidDocuments: [bobDidDocument],
                        encryptionAlgorithm: encryptionAlgorithm,
                        keyWrappingAlgorithm: isAuthenticated
                            ? KeyWrappingAlgorithm.ecdh1Pu
                            : KeyWrappingAlgorithm.ecdhEs,
                      );

                      final sharedMessageToBobInJson = jsonEncode(sut);

                      // Assert: unpack and check success

                      final expectedBodyContent = 'Hello, Bob!';

                      final actualPlainTextMessage =
                          await DidcommMessage.unpackToPlainTextMessage(
                        message: jsonDecode(
                          sharedMessageToBobInJson,
                        ) as Map<String, dynamic>,
                        recipientDidManager: bobDidManager,
                        validateAddressingConsistency: true,
                        expectedMessageWrappingTypes: [
                          isAuthenticated
                              ? MessageWrappingType.authcryptSignPlaintext
                              : MessageWrappingType.anoncryptSignPlaintext,
                        ],
                        expectedSigners: [
                          aliceDidDocument.assertionMethod.first.didKeyId,
                        ],
                      );

                      expect(actualPlainTextMessage, isNotNull);
                      expect(
                        actualPlainTextMessage.body?['content'],
                        expectedBodyContent,
                      );

                      final actualJweHeader =
                          const JweHeaderConverter().fromJson(
                        sut.protected,
                      );

                      // make sure sender identity does not leak for anonymous authentication
                      if (isAuthenticated) {
                        expect(actualJweHeader.subjectKeyId, isNotNull);
                        expect(actualJweHeader.agreementPartyUInfo, isNotNull);
                      } else {
                        expect(actualJweHeader.subjectKeyId, isNull);
                        expect(actualJweHeader.agreementPartyUInfo, isNull);
                      }
                    },
                  );

                  test(
                    'Fails to unpack encrypted message with authentication due to missing key',
                    () async {
                      // Act: create, sign, and encrypt the message
                      const content = 'Hello, Bob!';
                      final plainTextMessage = MessageAssertionService
                          .createPlainTextMessageAssertion(
                        content,
                        from: aliceDidDocument.id,
                        to: [bobDidDocument.id],
                      );

                      // find keys whose curve is common in other DID Documents
                      final aliceMatchedDidKeyIds =
                          aliceDidDocument.matchKeysInKeyAgreement(
                        otherDidDocuments: [
                          bobDidDocument,
                        ],
                      );

                      final sut = await EncryptedMessage.packWithAuthentication(
                        plainTextMessage,
                        keyPair: await aliceDidManager.getKeyPairByDidKeyId(
                          aliceMatchedDidKeyIds.first,
                        ),
                        didKeyId: aliceMatchedDidKeyIds.first,
                        recipientDidDocuments: [bobDidDocument],
                        encryptionAlgorithm: encryptionAlgorithm,
                      );

                      final sharedMessageToBobInJson = jsonEncode(sut);

                      // Assert: unpack and check success

                      // Simulate a missing key by modifying the recipient's key ID
                      final receivedMessage = jsonDecode(
                        sharedMessageToBobInJson,
                      ) as Map<String, dynamic>;

                      // ignore: avoid_dynamic_calls
                      receivedMessage['recipients'][0]['header']['kid'] =
                          'non-existent-key-id';

                      final actualFuture =
                          DidcommMessage.unpackToPlainTextMessage(
                        message: receivedMessage,
                        recipientDidManager: bobDidManager,
                      );

                      await expectLater(
                          actualFuture, throwsA(isA<Exception>()));
                    },
                  );

                  // TODO: wrap failed decryption that throw 'Invalid ' with own exception
                });
              }
            });
          }
        });
      }
    });
  });
}
