import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../didcomm.dart';
import '../common/authentication_tokens/authentication_tokens.dart';
import '../common/did_document_service_type.dart';
import '../extensions/extensions.dart';

// TODO: should be eventually moved to TDK
/// Authentication by mediators are not covered by standard.
/// This extension method provides authentication for the Affinidi mediator specifically.
extension AffinidiAuthenticatorExtension on MediatorClient {
  Future<AuthenticationTokens> authenticate({
    EncryptionAlgorithm encryptionAlgorithm = EncryptionAlgorithm.a256cbc,
  }) async {
    final dio = mediatorDidDocument.toDio(
      mediatorServiceType: DidDocumentServiceType.authentication,
    );

    final didDocument = DidKey.generateDocument(keyPair.publicKey);

    final challengeResponse = await dio.post<Map<String, dynamic>>(
      '/challenge',
      data: {'did': didDocument.id},
    );

    final createdTime = DateTime.now().toUtc();
    final expiresTime = createdTime.add(const Duration(seconds: 60));

    final plainTextMessage = PlainTextMessage(
      id: const Uuid().v4(),
      // this is specific to affinidi mediator
      type: Uri.parse('https://affinidi.com/atm/1.0/authenticate'),
      createdTime: createdTime,
      expiresTime: expiresTime,
      from: didDocument.id,
      to: [mediatorDidDocument.id],
      body: challengeResponse.data!['data'] as Map<String, dynamic>,
    );

    final encryptedMessage =
        await DidcommMessage.packIntoSignedAndEncryptedMessages(
      plainTextMessage,
      keyPair: keyPair,
      didKeyId: didKeyId,
      recipientDidDocuments: [mediatorDidDocument],
      encryptionAlgorithm: encryptionAlgorithm,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
      signer: signer,
    );

    final authenticateResponse = await dio.post<Map<String, dynamic>>(
      '',
      data: encryptedMessage,
    );

    return AuthenticationTokens.fromJson(
      authenticateResponse.data!['data'] as Map<String, dynamic>,
    );
  }
}
