import 'dart:convert';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/create_message_assertion.dart';

void main() async {
  final jweHeaderConverter = const JweHeaderConverter();

  group('Encrypted message', () {
    final aliceKeyStore = InMemoryKeyStore();
    final aliceWallet = PersistentWallet(aliceKeyStore);

    final bobKeyStore = InMemoryKeyStore();
    final bobWallet = PersistentWallet(bobKeyStore);

    final keyType = KeyType.p256;
    final encryptionAlgorithm = EncryptionAlgorithm.a256cbc;

    group('DidcommMessage', () {
      final aliceKeyId = 'alice-key-1-${keyType.name}';
      final bobKeyId = 'bob-key-1-${keyType.name}';

      late DidManager aliceDidManager;
      late DidManager bobDidManager;
      late KeyPair aliceKeyPair;
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

        aliceKeyPair = await aliceWallet.generateKey(
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

      test(
        '${MessageWrappingType.plaintext.name} message packing and unpacking',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
          );

          final sut = plainTextMessage;

          final sharedMessageToBobInJson = jsonEncode(sut);

          final expectedBodyContent = 'Hello, Bob!';
          final expectedMessageWrappingType = MessageWrappingType.plaintext;

          final actualPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: [expectedMessageWrappingType],
          );

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
          );
        },
      );

      test(
        '${MessageWrappingType.signedPlaintext.name} message packing and unpacking',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
          );

          final sut = await DidcommMessage.packIntoSignedMessage(
            plainTextMessage,
            signer: aliceSigner,
          );

          final sharedMessageToBobInJson = jsonEncode(sut);

          final expectedBodyContent = 'Hello, Bob!';
          final expectedMessageWrappingType =
              MessageWrappingType.signedPlaintext;

          final actualPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: [expectedMessageWrappingType],
          );

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
          );
        },
      );

      test(
        '${MessageWrappingType.anoncryptPlaintext.name} message packing and unpacking',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            to: [bobDidDocument.id],
          );

          final sut = await DidcommMessage.packIntoEncryptedMessage(
            plainTextMessage,
            keyType: aliceKeyPair.publicKey.type,
            recipientDidDocuments: [bobDidDocument],
            encryptionAlgorithm: encryptionAlgorithm,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
          );

          final sharedMessageToBobInJson = jsonEncode(sut);

          final expectedBodyContent = 'Hello, Bob!';
          final expectedMessageWrappingType =
              MessageWrappingType.anoncryptPlaintext;

          final actualPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: [expectedMessageWrappingType],
          );

          final actualJweHeader = jweHeaderConverter.fromJson(sut.protected);

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
          );

          expect(
            actualPlainTextMessage.from,
            isNull,
          );

          expect(
            actualJweHeader.subjectKeyId,
            isNull,
          );

          expect(
            actualJweHeader.agreementPartyUInfo,
            isNull,
          );
        },
      );

      test(
        '${MessageWrappingType.authcryptPlaintext.name} message packing and unpacking',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
          );

          final sut = await DidcommMessage.packIntoEncryptedMessage(
            plainTextMessage,
            keyPair: aliceKeyPair,
            didKeyId: aliceDidDocument.keyAgreement.first.id,
            recipientDidDocuments: [bobDidDocument],
            encryptionAlgorithm: encryptionAlgorithm,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
          );

          final sharedMessageToBobInJson = jsonEncode(sut);

          final expectedBodyContent = 'Hello, Bob!';
          final expectedMessageWrappingType =
              MessageWrappingType.authcryptPlaintext;

          final actualPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: [expectedMessageWrappingType],
          );

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
          );
        },
      );

      test(
        '${MessageWrappingType.anoncryptSignPlaintext.name} message packing and unpacking',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
          );

          final sut = await DidcommMessage.packIntoSignedAndEncryptedMessages(
            plainTextMessage,
            keyType: aliceKeyPair.publicKey.type,
            recipientDidDocuments: [bobDidDocument],
            encryptionAlgorithm: encryptionAlgorithm,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
            signer: aliceSigner,
          );

          final sharedMessageToBobInJson = jsonEncode(sut);

          final expectedBodyContent = 'Hello, Bob!';
          final expectedSigner =
              aliceDidDocument.assertionMethod.first.didKeyId;

          final expectedMessageWrappingType =
              MessageWrappingType.anoncryptSignPlaintext;

          final actualPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: [expectedMessageWrappingType],
            expectedSigners: [expectedSigner],
          );

          final actualJweHeader = jweHeaderConverter.fromJson(sut.protected);

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
          );

          expect(
            actualJweHeader.subjectKeyId,
            isNull,
          );

          expect(
            actualJweHeader.agreementPartyUInfo,
            isNull,
          );
        },
      );

      test(
        '${MessageWrappingType.authcryptSignPlaintext.name} message packing and unpacking',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
          );

          final sut = await DidcommMessage.packIntoSignedAndEncryptedMessages(
            plainTextMessage,
            keyPair: aliceKeyPair,
            didKeyId: aliceDidDocument.keyAgreement.first.id,
            recipientDidDocuments: [bobDidDocument],
            encryptionAlgorithm: encryptionAlgorithm,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
            signer: aliceSigner,
          );

          final sharedMessageToBobInJson = jsonEncode(sut);

          final expectedBodyContent = 'Hello, Bob!';
          final expectedSigner =
              aliceDidDocument.assertionMethod.first.didKeyId;

          final expectedMessageWrappingType =
              MessageWrappingType.authcryptSignPlaintext;

          final actualPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: [expectedMessageWrappingType],
            expectedSigners: [expectedSigner],
          );

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
          );
        },
      );

      test(
        '${MessageWrappingType.anoncryptAuthcryptPlaintext.name} message packing and unpacking',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
          );

          final sut =
              await DidcommMessage.packIntoAnoncryptAndAuthcryptMessages(
            plainTextMessage,
            keyPair: aliceKeyPair,
            didKeyId: aliceDidDocument.keyAgreement.first.id,
            recipientDidDocuments: [bobDidDocument],
            encryptionAlgorithm: encryptionAlgorithm,
          );

          final sharedMessageToBobInJson = jsonEncode(sut);

          final expectedBodyContent = 'Hello, Bob!';
          final expectedMessageWrappingType =
              MessageWrappingType.anoncryptAuthcryptPlaintext;

          final actualPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: [expectedMessageWrappingType],
          );

          final actualJweHeader = jweHeaderConverter.fromJson(sut.protected);

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
          );

          expect(
            actualJweHeader.subjectKeyId,
            isNull,
          );

          expect(
            actualJweHeader.agreementPartyUInfo,
            isNull,
          );
        },
      );

      test(
        '${MessageWrappingType.authcryptPlaintext.name} should be expected by default',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
          );

          final sut = await DidcommMessage.packIntoEncryptedMessage(
            plainTextMessage,
            keyPair: aliceKeyPair,
            didKeyId: aliceDidDocument.keyAgreement.first.id,
            recipientDidDocuments: [bobDidDocument],
            encryptionAlgorithm: encryptionAlgorithm,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
          );

          final sharedMessageToBobInJson = jsonEncode(sut);

          final expectedBodyContent = 'Hello, Bob!';
          final List<MessageWrappingType>? expectedMessageWrappingTypes = null;

          final actualPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: expectedMessageWrappingTypes,
          );

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
          );
        },
      );

      test(
        'should fail to unpack a message with unexpected wrapping type',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
          );

          final sut = plainTextMessage;
          final sharedMessageToBobInJson = jsonEncode(sut);

          final expectedMessageWrappingType =
              MessageWrappingType.signedPlaintext;

          final actualPlainTextMessageFuture =
              DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: [expectedMessageWrappingType],
          );

          expect(
            () async => await actualPlainTextMessageFuture,
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                'MessageWrappingType.plaintext in not in expected list: [MessageWrappingType.signedPlaintext]',
              ),
            ),
          );
        },
      );

      test(
        'should fail to unpack an ${MessageWrappingType.anoncryptPlaintext.name} message with a from != null',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
          );

          final sut = await DidcommMessage.packIntoEncryptedMessage(
            plainTextMessage,
            keyType: aliceKeyPair.publicKey.type,
            recipientDidDocuments: [bobDidDocument],
            encryptionAlgorithm: encryptionAlgorithm,
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
          );

          final sharedMessageToBobInJson = jsonEncode(sut);

          final actualPlainTextMessageFuture =
              DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            expectedMessageWrappingTypes: [
              MessageWrappingType.anoncryptPlaintext
            ],
          );

          expect(
            () async => await actualPlainTextMessageFuture,
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                'from header in a Plain Text Message must be null for ${MessageWrappingType.anoncryptPlaintext.name}',
              ),
            ),
          );
        },
      );

      test(
        [
          'should fail to unpack',
          '${MessageWrappingType.anoncryptPlaintext.name}, ${MessageWrappingType.anoncryptSignPlaintext.name},',
          'and ${MessageWrappingType.anoncryptAuthcryptPlaintext.name} messages',
          'if skid or apu is non null'
        ].join(' '),
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            to: [bobDidDocument.id],
          );

          final messages = [
            await DidcommMessage.packIntoEncryptedMessage(
              plainTextMessage,
              keyType: aliceKeyPair.publicKey.type,
              recipientDidDocuments: [bobDidDocument],
              encryptionAlgorithm: encryptionAlgorithm,
              keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
            ),
            await DidcommMessage.packIntoSignedAndEncryptedMessages(
              plainTextMessage,
              keyType: aliceKeyPair.publicKey.type,
              signer: aliceSigner,
              recipientDidDocuments: [bobDidDocument],
              encryptionAlgorithm: encryptionAlgorithm,
              keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
            ),
            await DidcommMessage.packIntoAnoncryptAndAuthcryptMessages(
              plainTextMessage,
              keyPair: aliceKeyPair,
              didKeyId: aliceDidDocument.keyAgreement.first.id,
              recipientDidDocuments: [bobDidDocument],
              encryptionAlgorithm: encryptionAlgorithm,
            ),
          ].map((message) => message.toJson()).toList();

          for (final message in messages) {
            final jweHeader = jweHeaderConverter
                .fromJson(
                  message['protected'] as String,
                )
                .toJson();

            // simulate a malicious intermediary that tampers with the message
            // by adding skid to the JWE header
            jweHeader['skid'] = 'some-skid';
            message['protected'] =
                jweHeaderConverter.toJson(JweHeader.fromJson(jweHeader));

            final sharedMessageToBobInJson = jsonEncode(message);

            final actualPlainTextMessageFuture =
                DidcommMessage.unpackToPlainTextMessage(
              message: jsonDecode(
                sharedMessageToBobInJson,
              ) as Map<String, dynamic>,
              recipientDidManager: bobDidManager,
              expectedMessageWrappingTypes: [
                MessageWrappingType.anoncryptPlaintext
              ],
            );

            expect(
              () async => await actualPlainTextMessageFuture,
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'skid',
                  'skid must be null for ${KeyWrappingAlgorithm.ecdhEs.value}',
                ),
              ),
            );
          }

          for (final message in messages) {
            final jweHeader = jweHeaderConverter
                .fromJson(
                  message['protected'] as String,
                )
                .toJson();

            jweHeader['skid'] = null;

            // simulate a malicious intermediary that tampers with the message
            // by adding apu to the JWE header
            jweHeader['apu'] = 'some-apu';
            message['protected'] =
                jweHeaderConverter.toJson(JweHeader.fromJson(jweHeader));

            final sharedMessageToBobInJson = jsonEncode(message);

            final actualPlainTextMessageFuture =
                DidcommMessage.unpackToPlainTextMessage(
              message: jsonDecode(
                sharedMessageToBobInJson,
              ) as Map<String, dynamic>,
              recipientDidManager: bobDidManager,
              expectedMessageWrappingTypes: [
                MessageWrappingType.anoncryptPlaintext
              ],
            );

            expect(
              () async => await actualPlainTextMessageFuture,
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'apu',
                  'apu must be null for ${KeyWrappingAlgorithm.ecdhEs.value}',
                ),
              ),
            );
          }
        },
      );
    });
  });
}
