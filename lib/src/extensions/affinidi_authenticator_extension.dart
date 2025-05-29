import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../extensions/extensions.dart';
import '../mediator_client/mediator_service_type.dart';
import '../messages/algorithm_types/encryption_algorithm.dart';
import '../jwks/jwks.dart';

/// Authentication by mediators are not covered by standard.
/// This extension method provides authentication for the Affinidi mediator specifically.
extension AffinidiAuthenticatorExtension on MediatorClient {
  Future<String> authenticate({
    required Wallet senderWallet,
    required String senderKeyId,
    required DidDocument mediatorDidDocument,
    EncryptionAlgorithm encryptionAlgorithm = EncryptionAlgorithm.a256cbc,
  }) async {
    final dio = didDocument.toDio(
      mediatorServiceType: MediatorServiceType.authentication,
    );

    final senderPublicKey = await senderWallet.getPublicKey(senderKeyId);
    final senderDidDocument = DidKey.generateDocument(senderPublicKey);

    final challengeResponse = await dio.post(
      '/challenge',
      data: {'did': senderDidDocument.id},
    );

    final createdTime = DateTime.now().toUtc();
    final expiresTime = createdTime.add(const Duration(seconds: 60));

    final plainTextMessage = PlainTextMessage(
      id: Uuid().v4(),
      // this is specif to affinidi mediator
      type: Uri.parse('https://affinidi.com/atm/1.0/authenticate'),
      createdTime: createdTime,
      expiresTime: expiresTime,
      from: senderDidDocument.id,
      to: [mediatorDidDocument.id],
      body: challengeResponse.data['data'],
    );

    final mediatorJwks = mediatorDidDocument.keyAgreement.map((keyAgreement) {
      final jwk = keyAgreement.asJwk().toJson();
      // TODO: kid is not available in the Jwk anymore. clarify with the team
      jwk['kid'] = keyAgreement.id;

      return jwk;
    }).toList();

    final encryptedMessage = await EncryptedMessage.packWithAuthentication(
      plainTextMessage,
      wallet: senderWallet,
      keyId: senderKeyId,
      jwksPerRecipient: [
        Jwks.fromJson({
          'keys': mediatorJwks,
        }),
      ],
      encryptionAlgorithm: encryptionAlgorithm,
    );

    final authenticateResponse = await dio.post(
      '',
      data: encryptedMessage,
    );

    print(authenticateResponse.data);

    return '';
  }
}
