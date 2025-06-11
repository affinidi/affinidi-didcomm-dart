import 'dart:convert';
import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/algorithms_types.dart';
import 'package:didcomm/src/messages/didcomm_message.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

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
        for (final isAuthenticated in [true, false]) {
          group(isAuthenticated ? 'Authenticated' : 'Anonymous', () {
            group(keyType.name, () {
              final aliceKeyId = 'alice-key-1-${keyType.name}';
              final bobKeyId = 'bob-key-1-${keyType.name}';

              late DidDocument aliceDidDocument;
              late DidDocument bobDidDocument;
              late DidSigner aliceSigner;

              late Map<String, dynamic> bobJwk;

              setUp(() async {
                final aliceKeyPair = await aliceWallet.generateKey(
                  keyId: aliceKeyId,
                  keyType: keyType,
                );

                aliceDidDocument =
                    DidKey.generateDocument(aliceKeyPair.publicKey);

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

                bobJwk = bobDidDocument.keyAgreement[0].asJwk().toJson();
                bobJwk['kid'] =
                    '${bobDidDocument.id}#${bobDidDocument.id.replaceFirst('did:key:', '')}';

                bobWallet.linkJwkKeyIdKeyWithKeyId(bobJwk['kid']!, bobKeyId);
              });

              for (final encryptionAlgorithm in [
                EncryptionAlgorithm.a256cbc,
                EncryptionAlgorithm.a256gcm
              ]) {
                group(encryptionAlgorithm.value, () {
                  test(
                    'Pack and unpack encrypted message with authentication successfully',
                    () async {
                      // Act: create, sign, and encrypt the message
                      final plainTextMessage = PlainTextMessage(
                        id: 'test-id',
                        from: aliceDidDocument.id,
                        to: [bobDidDocument.id],
                        type: Uri.parse(
                            'https://didcomm.org/example/1.0/message'),
                        body: {'content': 'Hello, Bob!'},
                      );

                      final signedMessage = await SignedMessage.pack(
                        plainTextMessage,
                        signer: aliceSigner,
                      );

                      final sut = await EncryptedMessage.pack(
                        signedMessage,
                        wallet: aliceWallet,
                        keyId: aliceKeyId,
                        jwksPerRecipient: [
                          Jwks.fromJson({
                            'keys': [bobJwk]
                          })
                        ],
                        encryptionAlgorithm: encryptionAlgorithm,
                        keyWrappingAlgorithm: isAuthenticated
                            ? KeyWrappingAlgorithm.ecdh1Pu
                            : KeyWrappingAlgorithm.ecdhEs,
                      );

                      final sharedMessageToBobInJson = jsonEncode(sut);

                      // Assert: unpack and check success

                      final expectedBodyContent = 'Hello, Bob!';

                      final actual =
                          await DidcommMessage.unpackToPlainTextMessage(
                        message: jsonDecode(sharedMessageToBobInJson),
                        recipientWallet: bobWallet,
                      );

                      expect(actual, isNotNull);
                      expect(actual!.body?['content'], expectedBodyContent);
                    },
                  );

                  test(
                    'Fails to unpack encrypted message with authentication due to missing key',
                    () async {
                      // Act: create, sign, and encrypt the message
                      final plainTextMessage = PlainTextMessage(
                        id: 'test-id',
                        from: aliceDidDocument.id,
                        to: [bobDidDocument.id],
                        type: Uri.parse(
                            'https://didcomm.org/example/1.0/message'),
                        body: {'content': 'Hello, Bob!'},
                      );

                      final sut = await EncryptedMessage.packWithAuthentication(
                        plainTextMessage,
                        wallet: aliceWallet,
                        keyId: aliceKeyId,
                        jwksPerRecipient: [
                          Jwks.fromJson({
                            'keys': [bobJwk]
                          })
                        ],
                        encryptionAlgorithm: encryptionAlgorithm,
                      );

                      final sharedMessageToBobInJson = jsonEncode(sut);

                      // Assert: unpack and check success

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
                });
              }
            });
          });
        }
      }
    });
  });
}
