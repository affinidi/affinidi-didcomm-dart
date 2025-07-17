import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/create_message_assertion.dart';

void main() {
  group('Encrypted message', () {
    final keyWrappingAlgorithm = KeyWrappingAlgorithm.ecdh1Pu;
    final encryptionAlgorithm = EncryptionAlgorithm.a256cbc;

    final aliceSeed = List<int>.generate(
      32,
      (index) => index + 1,
    );
    final bobSeed = List<int>.generate(
      32,
      (index) => index + 2,
    );

    final aliceWallet = Bip32Wallet.fromSeed(Uint8List.fromList(aliceSeed));
    final bobWallet = Bip32Wallet.fromSeed(Uint8List.fromList(bobSeed));

    group('BIP32', () {
      final aliceKeyId = "m/44'/60'/0'/0'/0'";
      final bobKeyId = "m/44'/60'/0'/0'/0'";

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
          keyType: KeyType.secp256k1,
        );

        await aliceDidManager.addVerificationMethod(aliceKeyId);
        aliceDidDocument = await aliceDidManager.getDidDocument();

        aliceSigner = await aliceDidManager.getSigner(
          aliceDidDocument.assertionMethod.first.id,
        );

        await bobWallet.generateKey(
          keyId: bobKeyId,
          keyType: KeyType.secp256k1,
        );

        await bobDidManager.addVerificationMethod(bobKeyId);
        bobDidDocument = await bobDidManager.getDidDocument();
      });
      test(
        'Pack and unpack encrypted message successfully',
        () async {
          const content = 'Hello, Bob!';
          final plainTextMessage =
              MessageAssertionService.createPlainTextMessageAssertion(
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
            otherDidDocuments: [bobDidDocument],
          );

          final sut = await EncryptedMessage.pack(signedMessage,
              keyPair: await aliceDidManager.getKeyPairByDidKeyId(
                aliceMatchedDidKeyIds.first,
              ),
              didKeyId: aliceMatchedDidKeyIds.first,
              recipientDidDocuments: [bobDidDocument],
              encryptionAlgorithm: encryptionAlgorithm,
              keyWrappingAlgorithm: keyWrappingAlgorithm);

          final sharedMessageToBobInJson = jsonEncode(sut);

          final actual = await DidcommMessage.unpackToPlainTextMessage(
            message: jsonDecode(
              sharedMessageToBobInJson,
            ) as Map<String, dynamic>,
            recipientDidManager: bobDidManager,
            validateAddressingConsistency: true,
            expectedMessageWrappingTypes: [
              MessageWrappingType.authcryptSignPlaintext
            ],
            expectedSigners: [
              aliceDidDocument.assertionMethod.first.didKeyId,
            ],
          );

          expect(actual, isNotNull);
          expect(actual.body?['content'], content);

          final actualJweHeader = const JweHeaderConverter().fromJson(
            sut.protected,
          );

          expect(actualJweHeader.agreementPartyUInfo, isNotNull);
        },
      );
    });
  });
}
