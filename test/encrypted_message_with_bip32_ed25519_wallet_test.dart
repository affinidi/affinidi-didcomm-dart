import 'dart:convert';
import 'dart:typed_data';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/converters/jwe_header_converter.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/extensions/verification_method_list_extention.dart';
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

      late Jwks bobJwks;

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

        final aliceJwks = aliceDidDocument.keyAgreement.toJwks();

        for (var jwk in aliceJwks.keys) {
          // Important! link JWK, so the wallet should be able to find the key pair by JWK
          // It will be replaced with DID Manager
          aliceWallet.linkJwkKeyIdKeyWithKeyId(jwk.keyId!, aliceKeyId);
        }

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

        final bobX25519PublicKey = await bobWallet.getX25519PublicKey(
          bobKeyPair.id,
        );

        bobDidDocument = DidKey.generateDocument(
          PublicKey(bobKeyId, bobX25519PublicKey, KeyType.x25519),
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

                  // find keys whose curve is common in other DID Documents
                  final aliceMatchedKeyIds =
                      aliceDidDocument.getKeyIdsWithCommonType(
                    wallet: aliceWallet,
                    otherDidDocuments: [
                      bobDidDocument,
                    ],
                  );

                  final sut = await EncryptedMessage.pack(
                    signedMessage,
                    keyPair: await aliceWallet.generateKey(
                      keyId: aliceMatchedKeyIds.first,
                    ),
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
