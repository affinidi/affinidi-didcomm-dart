import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../../didcomm.dart';

class AffinidiAuthorizationProvider extends AuthorizationProvider {
  final DidDocument mediatorDidDocument;
  final KeyPair keyPair;
  final String didKeyId;
  final DidSigner signer;

  AffinidiAuthorizationProvider({
    required this.mediatorDidDocument,
    required this.keyPair,
    required this.didKeyId,
    required this.signer,
  });

  static Future<AffinidiAuthorizationProvider> init({
    required DidDocument mediatorDidDocument,
    required DidManager didManager,
  }) async {
    final ownDidDocument = await didManager.getDidDocument();

    final bobMatchedDidKeyIds = ownDidDocument.matchKeysInKeyAgreement(
      otherDidDocuments: [
        mediatorDidDocument,
      ],
    );

    if (bobMatchedDidKeyIds.isEmpty) {
      throw Exception(
        'No suitable key found for key agreement with the mediator.',
      );
    }

    final didKeyId = bobMatchedDidKeyIds.first;

    return AffinidiAuthorizationProvider(
      mediatorDidDocument: mediatorDidDocument,
      keyPair: await didManager.getKeyPairByDidKeyId(
        didKeyId,
      ),
      didKeyId: didKeyId,
      signer: await didManager.getSigner(
        didManager.authentication.first,
      ),
    );
  }

  @override
  Future<AuthorizationTokens> generateTokens() async {
    final dio = mediatorDidDocument.toDio(
      mediatorServiceType: DidDocumentServiceType.authentication,
    );

    final did = getDidFromId(didKeyId);

    try {
      final challengeResponse = await dio.post<Map<String, dynamic>>(
        '/challenge',
        data: {'did': did},
      );

      final createdTime = DateTime.now().toUtc();
      final expiresTime = createdTime.add(const Duration(seconds: 60));

      final plainTextMessage = PlainTextMessage(
        id: const Uuid().v4(),
        // this is specific to affinidi mediator
        type: Uri.parse('https://affinidi.com/atm/1.0/authenticate'),
        createdTime: createdTime,
        expiresTime: expiresTime,
        from: did,
        to: [mediatorDidDocument.id],
        body: challengeResponse.data!['data'] as Map<String, dynamic>,
      );

      final encryptedMessage =
          await DidcommMessage.packIntoSignedAndEncryptedMessages(
        plainTextMessage,
        keyPair: keyPair,
        didKeyId: didKeyId,
        recipientDidDocuments: [mediatorDidDocument],
        encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
        keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
        signer: signer,
      );

      final authenticateResponse = await dio.post<Map<String, dynamic>>(
        '',
        data: encryptedMessage,
      );

      return AuthorizationTokens.fromJson(
        authenticateResponse.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }
}
