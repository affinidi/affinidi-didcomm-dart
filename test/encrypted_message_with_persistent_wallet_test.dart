import 'dart:convert';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/create_message_assertion.dart';

void main() async {
  final keyWrappingToEncryptionAlgorithms = {
    KeyWrappingAlgorithm.ecdh1Pu: [
      EncryptionAlgorithm.a256cbc,
    ],
    KeyWrappingAlgorithm.ecdhEs: [
      EncryptionAlgorithm.a256cbc,
      EncryptionAlgorithm.a256gcm,
    ],
  };

  group('Encrypted message', () {
    final aliceKeyStore = InMemoryKeyStore();
    final aliceWallet = PersistentWallet(aliceKeyStore);

    final bobKeyStore = InMemoryKeyStore();
    final bobWallet = PersistentWallet(bobKeyStore);
    group('Persisted wallet', () {
      for (final keyType in [
        KeyType.ed25519,
        KeyType.secp256k1,
        KeyType.p256,
        KeyType.p384,
        KeyType.p521,
      ]) {
        group(keyType.name, () {
          for (final didType in [
            'did:key',
            'did:peer',
          ]) {
            group(didType, () {
              final aliceKeyId = 'alice-key-1-${keyType.name}';
              final bobKeyId = 'bob-key-1-${keyType.name}';

              late DidManager aliceDidManager;
              late DidManager bobDidManager;
              late DidDocument aliceDidDocument;
              late DidDocument bobDidDocument;
              late DidSigner aliceSigner;

              setUp(() async {
                final useDidKey = didType == 'did:key';

                aliceDidManager = useDidKey
                    ? DidKeyManager(
                        wallet: aliceWallet,
                        store: InMemoryDidStore(),
                      )
                    : DidPeerManager(
                        wallet: aliceWallet,
                        store: InMemoryDidStore(),
                      );

                bobDidManager = useDidKey
                    ? DidKeyManager(
                        wallet: bobWallet,
                        store: InMemoryDidStore(),
                      )
                    : DidPeerManager(
                        wallet: bobWallet,
                        store: InMemoryDidStore(),
                      );

                await aliceWallet.generateKey(
                  keyId: aliceKeyId,
                  keyType: keyType,
                );

                // TODO: remove when Dart SSI updated
                if (!useDidKey && keyType == KeyType.secp256k1) {
                  await aliceDidManager
                      .addVerificationMethod(aliceKeyId, relationships: {
                    VerificationRelationship.authentication,
                    VerificationRelationship.assertionMethod,
                    VerificationRelationship.capabilityInvocation,
                    VerificationRelationship.capabilityDelegation,
                    VerificationRelationship.keyAgreement
                  });
                } else {
                  await aliceDidManager.addVerificationMethod(aliceKeyId);
                }

                aliceDidDocument = await aliceDidManager.getDidDocument();

                aliceSigner = await aliceDidManager.getSigner(
                  aliceDidDocument.assertionMethod.first.id,
                );

                await bobWallet.generateKey(
                  keyId: bobKeyId,
                  keyType: keyType,
                );

                // TODO: remove when Dart SSI updated
                if (!useDidKey && keyType == KeyType.secp256k1) {
                  await bobDidManager
                      .addVerificationMethod(bobKeyId, relationships: {
                    VerificationRelationship.authentication,
                    VerificationRelationship.assertionMethod,
                    VerificationRelationship.capabilityInvocation,
                    VerificationRelationship.capabilityDelegation,
                    VerificationRelationship.keyAgreement
                  });
                } else {
                  await bobDidManager.addVerificationMethod(bobKeyId);
                }

                bobDidDocument = await bobDidManager.getDidDocument();
              });

              for (final isAuthenticated in [true, false]) {
                final keyWrappingAlgorithm = isAuthenticated
                    ? KeyWrappingAlgorithm.ecdh1Pu
                    : KeyWrappingAlgorithm.ecdhEs;

                final encryptionAlgorithms =
                    keyWrappingToEncryptionAlgorithms[keyWrappingAlgorithm]!;

                group(isAuthenticated ? 'Authenticated' : 'Anonymous', () {
                  for (final encryptionAlgorithm in encryptionAlgorithms) {
                    group(encryptionAlgorithm.value, () {
                      test(
                        'Pack and unpack encrypted message successfully',
                        () async {
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
                            keyWrappingAlgorithm: keyWrappingAlgorithm,
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
                            expect(
                                actualJweHeader.agreementPartyUInfo, isNotNull);
                          } else {
                            expect(actualJweHeader.subjectKeyId, isNull);
                            expect(actualJweHeader.agreementPartyUInfo, isNull);
                          }
                        },
                      );

                      test(
                        'Fails to unpack encrypted message with authentication due to missing key',
                        () async {
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

                          final sut = await EncryptedMessage.pack(
                            plainTextMessage,
                            keyPair: isAuthenticated
                                ? await aliceDidManager.getKeyPairByDidKeyId(
                                    aliceMatchedDidKeyIds.first,
                                  )
                                : null,
                            didKeyId: aliceMatchedDidKeyIds.first,
                            keyType: isAuthenticated
                                ? null
                                : [
                                    bobDidDocument
                                    // other recipients here
                                  ].getCommonKeyTypesInKeyAgreements().first,
                            recipientDidDocuments: [bobDidDocument],
                            encryptionAlgorithm: encryptionAlgorithm,
                            keyWrappingAlgorithm: keyWrappingAlgorithm,
                          );

                          final sharedMessageToBobInJson = jsonEncode(sut);

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
                            actualFuture,
                            throwsA(isA<Exception>()),
                          );
                        },
                      );

                      // TODO: wrap failed decryption that throw 'Invalid ' with own exception
                    });
                  }
                });
              }

              group(
                  'Prevent ${EncryptionAlgorithm.a256gcm.value} to be used together with ${KeyWrappingAlgorithm.ecdh1Pu}',
                  () {
                test('Should fail to pack', () async {
                  const content = 'Hello, Bob!';
                  final plainTextMessage =
                      MessageAssertionService.createPlainTextMessageAssertion(
                    content,
                    from: aliceDidDocument.id,
                    to: [bobDidDocument.id],
                  );

                  final actualFuture = EncryptedMessage.pack(
                    plainTextMessage,
                    keyPair: await aliceDidManager.getKeyPairByDidKeyId(
                      aliceDidDocument.assertionMethod.first.didKeyId,
                    ),
                    didKeyId: aliceDidDocument.assertionMethod.first.didKeyId,
                    recipientDidDocuments: [bobDidDocument],
                    encryptionAlgorithm: EncryptionAlgorithm.a256gcm,
                    keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
                  );

                  await expectLater(
                    actualFuture,
                    throwsA(
                      isA<IncompatibleEncryptionAlgorithmWithAuthcrypt>(),
                    ),
                  );
                });

                test('Should fail to unpack', () async {
                  const content = 'Hello, Bob!';
                  final plainTextMessage =
                      MessageAssertionService.createPlainTextMessageAssertion(
                    content,
                    from: aliceDidDocument.id,
                    to: [bobDidDocument.id],
                  );

                  final encryptedMessage = await EncryptedMessage.pack(
                    plainTextMessage,
                    keyPair: await aliceDidManager.getKeyPairByDidKeyId(
                      aliceDidDocument.assertionMethod.first.didKeyId,
                    ),
                    didKeyId: aliceDidDocument.assertionMethod.first.didKeyId,
                    recipientDidDocuments: [bobDidDocument],
                    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
                    keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
                  );

                  final converter = const JweHeaderConverter();

                  final json = encryptedMessage.toJson();
                  final jwe = converter.fromJson(json['protected'] as String);

                  // Simulate a message with a256gcm encryption algorithm with ecdh1Pu
                  final modifiedJwe = JweHeader(
                    keyWrappingAlgorithm: jwe.keyWrappingAlgorithm,
                    encryptionAlgorithm: EncryptionAlgorithm.a256gcm,
                    ephemeralKey: jwe.ephemeralKey,
                    agreementPartyVInfo: jwe.agreementPartyVInfo,
                  );

                  json['protected'] = converter.toJson(modifiedJwe);

                  final actualFuture = DidcommMessage.unpackToPlainTextMessage(
                    message: json,
                    recipientDidManager: bobDidManager,
                  );

                  await expectLater(
                    actualFuture,
                    throwsA(
                      isA<IncompatibleEncryptionAlgorithmWithAuthcrypt>(),
                    ),
                  );
                });
              });
            });
          }
        });
      }
    });
  });
}
