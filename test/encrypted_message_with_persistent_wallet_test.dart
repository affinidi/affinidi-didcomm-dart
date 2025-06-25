import 'dart:convert';
import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/converters/jwe_header_converter.dart';
import 'package:didcomm/src/extensions/extensions.dart';
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

          late DidDocument aliceDidDocument;
          late DidDocument bobDidDocument;
          late DidSigner aliceSigner;

          setUp(() async {
            final aliceKeyPair = await aliceWallet.generateKey(
              keyId: aliceKeyId,
              keyType: keyType,
            );

            aliceDidDocument = DidKey.generateDocument(aliceKeyPair.publicKey);

            for (var keyAgreement in aliceDidDocument.keyAgreement) {
              // Important! link JWK, so the wallet should be able to find the key pair by JWK
              // It will be replaced with DID Manager
              aliceWallet.linkDidKeyIdKeyWithKeyId(keyAgreement.id, aliceKeyId);
            }

            aliceSigner = DidSigner(
              didDocument: aliceDidDocument,
              keyPair: aliceKeyPair,
              didKeyId: aliceDidDocument.verificationMethod[0].id,
              signatureScheme: SignatureScheme.ecdsa_p256_sha256,
            );

            final bobKeyPair = await bobWallet.generateKey(
              keyId: bobKeyId,
              keyType: keyType,
            );

            bobDidDocument = DidKey.generateDocument(bobKeyPair.publicKey);

            for (var keyAgreement in bobDidDocument.keyAgreement) {
              // Important! link JWK, so the wallet should be able to find the key pair by JWK
              // It will be replaced with DID Manager
              bobWallet.linkDidKeyIdKeyWithKeyId(keyAgreement.id, bobKeyId);
            }
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
                      final plainTextMessage = await MessageAssertionService
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
                      final aliceMatchedKeyIds =
                          aliceDidDocument.matchKeysInKeyAgreement(
                        wallet: aliceWallet,
                        otherDidDocuments: [
                          bobDidDocument,
                        ],
                      );

                      final sut = await EncryptedMessage.pack(
                        signedMessage,
                        keyPair: await aliceWallet.getKeyPair(
                          aliceMatchedKeyIds.first,
                        ),
                        didKeyId: aliceWallet.getDidIdByKeyId(
                          aliceMatchedKeyIds.first,
                        )!,
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
                        message: jsonDecode(sharedMessageToBobInJson),
                        recipientWallet: bobWallet,
                        expectedMessageWrappingTypes: [
                          isAuthenticated
                              ? MessageWrappingType.authcryptSignPlaintext
                              : MessageWrappingType.anoncryptSignPlaintext,
                        ],
                      );

                      expect(actualPlainTextMessage, isNotNull);
                      expect(
                        actualPlainTextMessage.body?['content'],
                        expectedBodyContent,
                      );

                      final actualJweHeader = JweHeaderConverter().fromJson(
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
                      final plainTextMessage = await MessageAssertionService
                          .createPlainTextMessageAssertion(
                        content,
                        from: aliceDidDocument.id,
                        to: [bobDidDocument.id],
                      );

                      // find keys whose curve is common in other DID Documents
                      final aliceMatchedKeyIds =
                          aliceDidDocument.matchKeysInKeyAgreement(
                        wallet: aliceWallet,
                        otherDidDocuments: [
                          bobDidDocument,
                        ],
                      );

                      final sut = await EncryptedMessage.packWithAuthentication(
                        plainTextMessage,
                        keyPair: await aliceWallet.getKeyPair(
                          aliceMatchedKeyIds.first,
                        ),
                        didKeyId: aliceWallet.getDidIdByKeyId(
                          aliceMatchedKeyIds.first,
                        )!,
                        recipientDidDocuments: [bobDidDocument],
                        encryptionAlgorithm: encryptionAlgorithm,
                      );

                      final sharedMessageToBobInJson = jsonEncode(sut);

                      // Assert: unpack and check success

                      // Simulate a missing key by modifying the recipient's key ID
                      final receivedMessage =
                          jsonDecode(sharedMessageToBobInJson);
                      receivedMessage['recipients'][0]['header']['kid'] =
                          'non-existent-key-id';

                      final actualFuture =
                          DidcommMessage.unpackToPlainTextMessage(
                        message: receivedMessage,
                        recipientWallet: bobWallet,
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
