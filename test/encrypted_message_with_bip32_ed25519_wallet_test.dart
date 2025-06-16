import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/encryption_algorithm.dart';
import 'package:didcomm/src/messages/didcomm_message.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/create_message_assertion.dart';

void main() {
  group("Encrypted message", () {
    final aliceSeed = List<int>.generate(
      32,
      (index) => index + 1,
    );
    final bobSeed = List<int>.generate(
      32,
      (index) => index + 2,
    );
    final aliceWallet =
        Bip32Ed25519Wallet.fromSeed(Uint8List.fromList(aliceSeed));
    final bobWallet = Bip32Ed25519Wallet.fromSeed(Uint8List.fromList(bobSeed));

    group("BIP32 Ed25519", () {
      final aliceKeyId = "m/44'/60'/0'/0'/0'";
      final bobKeyId = "m/44'/60'/0'/0'/0'";

      late DidDocument aliceDidDocument;
      late DidDocument bobDidDocument;
      late DidSigner aliceSigner;

      late Map<String, dynamic> bobJwk;

      setUp(() async {
        final aliceKeyPair = await aliceWallet.generateKey(
          keyId: aliceKeyId,
          keyType: KeyType.ed25519,
        );
        final aliceX25519PublicKey = await aliceWallet.getX25519PublicKey(
          aliceKeyPair.id,
        );

        aliceDidDocument = DidKey.generateDocument(
          PublicKey(aliceKeyId, aliceX25519PublicKey, KeyType.x25519),
        );

        aliceSigner = DidSigner(
          didDocument: aliceDidDocument,
          keyPair: aliceKeyPair,
          didKeyId: aliceDidDocument.verificationMethod[0].id,
          signatureScheme: SignatureScheme.eddsa_sha512,
        );

        final bobKeyPair = await bobWallet.generateKey(
          keyId: bobKeyId,
          keyType: KeyType.ed25519,
        );

        final bobX25519PublicKey =
            await bobWallet.getX25519PublicKey(bobKeyPair.id);

        bobDidDocument = DidKey.generateDocument(
          PublicKey(bobKeyId, bobX25519PublicKey, KeyType.x25519),
        );

        bobJwk = bobDidDocument.keyAgreement[0].asJwk().toJson();
        bobJwk['kid'] =
            '${bobDidDocument.id}#${bobDidDocument.id.replaceFirst('did:key:', '')}';

        bobWallet.linkJwkKeyIdKeyWithKeyId(bobJwk['kid']!, bobKeyId);
      });

      for (final encryptionAlgorithm in [
        EncryptionAlgorithm.a256cbc,
        EncryptionAlgorithm.a256gcm,
      ]) {
        group(encryptionAlgorithm.value.toString(), () {
          test(
            'Pack and unpack encrypted message successfully',
            () async {
              const content = 'Hello, Bob!';
              final plainTextMessage =
                  await MessageAssertionService.createPlainTextMessageAssertion(
                content,
                from: aliceDidDocument.id,
                to: [bobDidDocument.id],
              );

              final signedMessage = await SignedMessage.pack(
                plainTextMessage,
                signer: aliceSigner,
              );

              final sut = await EncryptedMessage.packWithAuthentication(
                signedMessage,
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

              final actual = await DidcommMessage.unpackToPlainTextMessage(
                message: jsonDecode(sharedMessageToBobInJson),
                recipientWallet: bobWallet,
              );

              expect(actual, isNotNull);
              expect(actual!.body?['content'], content);
            },
          );
        });
      }
    });
  });
}
