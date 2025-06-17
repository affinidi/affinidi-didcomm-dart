import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/converters/jwe_header_converter.dart';
import 'package:didcomm/src/extensions/verification_method_list_extention.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/algorithms_types.dart';
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
    final aliceWallet = Bip32Wallet.fromSeed(Uint8List.fromList(aliceSeed));
    final bobWallet = Bip32Wallet.fromSeed(Uint8List.fromList(bobSeed));

    group("BIP32", () {
      final aliceKeyId = "m/44'/60'/0'/0'/0'";
      final bobKeyId = "m/44'/60'/0'/0'/0'";

      late DidDocument aliceDidDocument;
      late DidDocument bobDidDocument;
      late DidSigner aliceSigner;

      late Jwks bobJwks;

      setUp(() async {
        final aliceKeyPair = await aliceWallet.generateKey(
          keyId: aliceKeyId,
          keyType: KeyType.secp256k1,
        );

        aliceDidDocument = DidKey.generateDocument(
          aliceKeyPair.publicKey,
        );

        aliceSigner = DidSigner(
          didDocument: aliceDidDocument,
          keyPair: aliceKeyPair,
          didKeyId: aliceDidDocument.verificationMethod[0].id,
          signatureScheme: SignatureScheme.ecdsa_secp256k1_sha256,
        );

        final bobKeyPair = await bobWallet.generateKey(
          keyId: bobKeyId,
          keyType: KeyType.secp256k1,
        );

        bobDidDocument = DidKey.generateDocument(
          bobKeyPair.publicKey,
        );

        bobJwks = bobDidDocument.keyAgreement.toJwks();

        for (var jwk in bobJwks.keys) {
          // Important! link JWK, so the wallet should be able to find the key pair by JWK
          // It will be replaced with DID Manager
          bobWallet.linkJwkKeyIdKeyWithKeyId(jwk.keyId!, bobKeyId);
        }
      });

      for (final encryptionAlgorithm in [
        EncryptionAlgorithm.a256cbc,
        EncryptionAlgorithm.a256gcm,
      ]) {
        group(encryptionAlgorithm.value.toString(), () {
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

                  final sut = await EncryptedMessage.pack(
                    signedMessage,
                    wallet: aliceWallet,
                    keyId: aliceKeyId,
                    jwksPerRecipient: [bobJwks],
                    encryptionAlgorithm: encryptionAlgorithm,
                    keyWrappingAlgorithm: isAuthenticated
                        ? KeyWrappingAlgorithm.ecdh1Pu
                        : KeyWrappingAlgorithm.ecdhEs,
                  );

                  final sharedMessageToBobInJson = jsonEncode(sut);

                  final actual = await DidcommMessage.unpackToPlainTextMessage(
                    message: jsonDecode(sharedMessageToBobInJson),
                    recipientWallet: bobWallet,
                  );

                  expect(actual, isNotNull);
                  expect(actual!.body?['content'], content);

                  final actualJweHeader = JweHeaderConverter().fromJson(
                    sut.protected,
                  );

                  // make sure sender identity does not leak for anonymous authentication
                  expect(
                    actualJweHeader.subjectKeyId,
                    isAuthenticated ? isNotNull : isNull,
                  );
                },
              );
            });
          }
        });
      }
    });
  });
}
