import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/create_message_assertion.dart';

void main() {
  group('Encrypted message', () {
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

      late DidController aliceDidController;
      late DidController bobDidController;
      late DidDocument aliceDidDocument;
      late DidDocument bobDidDocument;
      late DidSigner aliceSigner;

      setUp(() async {
        aliceDidController = DidKeyController(
          wallet: aliceWallet,
          store: InMemoryDidStore(),
        );

        bobDidController = DidKeyController(
          wallet: bobWallet,
          store: InMemoryDidStore(),
        );

        await aliceWallet.generateKey(
          keyId: aliceKeyId,
          keyType: KeyType.secp256k1,
        );

        await aliceDidController.addVerificationMethod(aliceKeyId);
        aliceDidDocument = await aliceDidController.getDidDocument();

        aliceSigner = await aliceDidController.getSigner(
          aliceDidDocument.assertionMethod.first.id,
        );

        await bobWallet.generateKey(
          keyId: bobKeyId,
          keyType: KeyType.secp256k1,
        );

        await bobDidController.addVerificationMethod(bobKeyId);
        bobDidDocument = await bobDidController.getDidDocument();
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

                  final sut = await EncryptedMessage.pack(
                    signedMessage,
                    keyPair: isAuthenticated
                        ? await aliceDidController.getKeyPairByDidKeyId(
                            aliceMatchedDidKeyIds.first,
                          )
                        : null,
                    didKeyId:
                        isAuthenticated ? aliceMatchedDidKeyIds.first : null,
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

                  final actual = await DidcommMessage.unpackToPlainTextMessage(
                    message: jsonDecode(
                      sharedMessageToBobInJson,
                    ) as Map<String, dynamic>,
                    recipientDidController: bobDidController,
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

                  expect(actual, isNotNull);
                  expect(actual.body?['content'], content);

                  final actualJweHeader = const JweHeaderConverter().fromJson(
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
            });
          }
        });
      }
    });
  });
}
