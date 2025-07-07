import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/extensions/did_signer_extension.dart';
import 'package:didcomm/src/extensions/object_extension.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/create_message_assertion.dart';

void main() async {
  final persistentWallet = PersistentWallet(
    InMemoryKeyStore(),
  );

  final seed = List<int>.generate(
    32,
    (index) => index + 1,
  );

  final bip32Wallet = Bip32Wallet.fromSeed(Uint8List.fromList(seed));

  final signatureSchemes = {
    KeyType.p256: SignatureScheme.ecdsa_p256_sha256,
    KeyType.ed25519: SignatureScheme.ed25519,
    KeyType.secp256k1: SignatureScheme.ecdsa_secp256k1_sha256,
  };

  final wallets = {
    KeyType.p256: persistentWallet,
    KeyType.ed25519: persistentWallet,
    KeyType.secp256k1: bip32Wallet,
  };

  final keyIds = {
    KeyType.p256: 'key-1-${KeyType.p256.name}',
    KeyType.ed25519: 'key-1-${KeyType.ed25519.name}',
    KeyType.secp256k1: "m/44'/60'/0'/0'/0'",
  };

  group('Encrypted message', () {
    for (final keyType in [
      KeyType.p256,
      KeyType.ed25519,
      KeyType.secp256k1,
    ]) {
      group(keyType.name, () {
        final keyId = keyIds[keyType]!;

        late DidController didController;
        late DidDocument didDocument;
        late DidSigner signer;

        setUp(() async {
          final wallet = wallets[keyType]!;

          didController = DidKeyController(
            wallet: wallet,
            store: InMemoryDidStore(),
          );

          await wallet.generateKey(
            keyId: keyId,
            keyType: keyType,
          );

          await didController.addVerificationMethod(keyId);
          didDocument = await didController.getDidDocument();

          final signatureScheme = signatureSchemes[keyType]!;

          signer = await didController.getSigner(
            didDocument.assertionMethod.first.id,
            signatureScheme: signatureScheme,
          );
        });

        test('Pack and unpack encrypted message successfully', () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: didDocument.id,
            to: ['did:rand:0x1234567890abcdef1234567890abcdef12345678'],
          );

          final signedMessage = await SignedMessage.pack(
            plainTextMessage,
            signer: signer,
          );

          expect(signedMessage.signatures, isNotNull);
          expect(
            signedMessage.signatures.first.header.keyId,
            didDocument.assertionMethod.first.didKeyId,
          );

          final unpackedPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: signedMessage.toJson(),
            recipientDidController: didController,
            validateAddressingConsistency: true,
            expectedMessageWrappingTypes: [
              MessageWrappingType.signedPlaintext,
            ],
            expectedSigners: [
              didDocument.assertionMethod.first.didKeyId,
            ],
          );

          expect(unpackedPlainTextMessage, isNotNull);
          expect(unpackedPlainTextMessage.body!['content'], content);
        });

        test('Should fail on invalid signature if there is only one signature',
            () async {
          // Act: create and sign the message
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: didDocument.id,
            to: ['did:rand:0x1234567890abcdef1234567890abcdef12345678'],
          );

          final signedMessage = await SignedMessage.pack(
            plainTextMessage,
            signer: signer,
          );

          final brokenMessage = signedMessage.toJson();

          // simulate invalid signature
          brokenMessage['payload'] = base64Encode(
            {'content': 'invalid data'}.toJsonBytes(),
          );

          final actualFuture = DidcommMessage.unpackToPlainTextMessage(
            message: brokenMessage,
            recipientDidController: didController,
            validateAddressingConsistency: true,
            expectedMessageWrappingTypes: [
              MessageWrappingType.signedPlaintext,
            ],
            expectedSigners: [
              didDocument.assertionMethod.first.didKeyId,
            ],
          );

          await expectLater(actualFuture, throwsA(isA<Exception>()));
        });

        test(
            'Pack and unpack encrypted message with multiple signatures successfully',
            () async {
          final extraDidController = DidKeyController(
            store: InMemoryDidStore(),
            wallet: PersistentWallet(InMemoryKeyStore()),
          );

          final extraKeyPair = await extraDidController.wallet.generateKey(
            // extra wallet always has p256
            keyType: KeyType.p256,
          );

          await extraDidController.addVerificationMethod(extraKeyPair.id);

          final extraSigner = await extraDidController.getSigner(
            (await extraDidController.getDidDocument())
                .assertionMethod
                .first
                .id,
            signatureScheme: SignatureScheme.ecdsa_p256_sha256,
          );

          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: didDocument.id,
            to: ['did:rand:0x1234567890abcdef1234567890abcdef12345678'],
          );

          final signedMessage = await SignedMessage.pack(
            plainTextMessage,
            signer: signer,
          );

          final extraSignedMessage = await SignedMessage.pack(
            plainTextMessage,
            signer: extraSigner,
          );

          signedMessage.signatures.add(
            extraSignedMessage.signatures.first,
          );

          expect(signedMessage.signatures, isNotNull);
          expect(
            signedMessage.signatures.first.header.keyId,
            didDocument.assertionMethod.first.didKeyId,
          );

          final unpackedPlainTextMessage =
              await DidcommMessage.unpackToPlainTextMessage(
            message: signedMessage.toJson(),
            recipientDidController: didController,
            validateAddressingConsistency: true,
            expectedMessageWrappingTypes: [
              MessageWrappingType.signedPlaintext,
            ],
            expectedSigners: [
              signer.didKeyId,
              extraSigner.didKeyId,
            ],
          );

          expect(unpackedPlainTextMessage, isNotNull);
          expect(unpackedPlainTextMessage.body!['content'], content);
        });

        test('Should fail on invalid signature if there are multiple signature',
            () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
            content,
            from: didDocument.id,
            to: ['did:rand:0x1234567890abcdef1234567890abcdef12345678'],
          );

          final signedMessage = await SignedMessage.pack(
            plainTextMessage,
            signer: signer,
          );

          final originalSignature = signedMessage.signatures.first;

          // simulate invalid signature additionally to a valid signature
          final fakeSignature = Signature(
            protected: originalSignature.protected,
            signature: Uint8List.fromList(
              List.filled(originalSignature.signature.length, 5),
            ),
            header: originalSignature.header,
          );

          signedMessage.signatures.add(fakeSignature);

          final actualFuture = DidcommMessage.unpackToPlainTextMessage(
            message: signedMessage.toJson(),
            recipientDidController: didController,
            validateAddressingConsistency: true,
            expectedMessageWrappingTypes: [
              MessageWrappingType.signedPlaintext,
            ],
            expectedSigners: [
              didDocument.assertionMethod.first.didKeyId,
            ],
          );

          await expectLater(actualFuture, throwsA(isA<Exception>()));
        });
      });
    }
  });
}
