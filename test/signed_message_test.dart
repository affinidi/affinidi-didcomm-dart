import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/extensions/did_signer_extension.dart';
import 'package:didcomm/src/extensions/object_extension.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/create_message_assertion.dart';

void main() async {
  group('Signed message', () {
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
            final useDidKey = didType == 'did:key';
            final keyId = 'key-1-${keyType.name}';

            late DidManager didManager;
            late DidDocument didDocument;
            late DidSigner signer;

            setUp(() async {
              final wallet = PersistentWallet(
                InMemoryKeyStore(),
              );

              didManager = useDidKey
                  ? DidKeyManager(
                      wallet: wallet,
                      store: InMemoryDidStore(),
                    )
                  : DidPeerManager(
                      wallet: wallet,
                      store: InMemoryDidStore(),
                    );

              await wallet.generateKey(
                keyId: keyId,
                keyType: keyType,
              );

              await didManager.addVerificationMethod(keyId);
              didDocument = await didManager.getDidDocument();

              signer = await didManager.getSigner(
                didDocument.assertionMethod.first.id,
              );
            });

            test('Pack and unpack signed message successfully', () async {
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
                recipientDidManager: didManager,
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

            test(
                'Should fail on invalid signature if there is only one signature',
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
                recipientDidManager: didManager,
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
              final extraDidManager = DidKeyManager(
                store: InMemoryDidStore(),
                wallet: PersistentWallet(InMemoryKeyStore()),
              );

              final extraKeyPair = await extraDidManager.wallet.generateKey(
                // extra wallet always has p256
                keyType: KeyType.p256,
              );

              await extraDidManager.addVerificationMethod(extraKeyPair.id);

              final extraSigner = await extraDidManager.getSigner(
                (await extraDidManager.getDidDocument())
                    .assertionMethod
                    .first
                    .id,
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
                recipientDidManager: didManager,
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

            test(
                'Should fail on invalid signature if there are multiple signature',
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
                recipientDidManager: didManager,
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
  });
}
