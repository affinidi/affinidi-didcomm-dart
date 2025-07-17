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

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
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

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
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

          final authcryptMessage =
              await EncryptedMessage.packWithAuthentication(
            plainTextMessage,
            keyPair: aliceKeyPair,
            didKeyId: aliceDidDocument.keyAgreement.first.id,
            recipientDidDocuments: [bobDidDocument],
          );

          final sut = await EncryptedMessage.packAnonymously(
            authcryptMessage,
            keyType: aliceKeyPair.publicKey.type,
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

          expect(
            actualPlainTextMessage.body?['content'],
            expectedBodyContent,
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
            throwsArgumentError,
          );
        },
      );
    });
  });
}
