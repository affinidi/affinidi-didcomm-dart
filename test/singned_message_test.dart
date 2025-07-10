import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
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

  group('Signed message', () {
    for (final keyType in [
      KeyType.p256,
      KeyType.ed25519,
      KeyType.secp256k1,
    ]) {
      group(keyType.name, () {
        final keyId = keyIds[keyType]!;

        late DidManager didManager;
        late DidDocument didDocument;
        late DidSigner signer;

        setUp(() async {
          final wallet = wallets[keyType]!;

          didManager = DidKeyManager(
            wallet: wallet,
            store: InMemoryDidStore(),
          );

          await wallet.generateKey(
            keyId: keyId,
            keyType: keyType,
          );

          await didManager.addVerificationMethod(keyId);
          didDocument = await didManager.getDidDocument();

          final signatureScheme = signatureSchemes[keyType]!;

          signer = await didManager.getSigner(
            didDocument.assertionMethod.first.id,
            signatureScheme: signatureScheme,
          );
        });

        test('Pack and unpack encrypted message successfully', () async {
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

        test('Should fail on invalid signature', () async {
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
      });
    }
  });
}
