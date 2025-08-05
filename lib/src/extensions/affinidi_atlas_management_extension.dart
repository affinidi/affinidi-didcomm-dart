import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../didcomm.dart';

class GetMediatorInstancesListMessage extends PlainTextMessage {
  GetMediatorInstancesListMessage({
    required super.id,
    required super.from,
    required super.to,
    super.createdTime,
    super.expiresTime,
  }) : super(
          type: Uri.parse(
            'affinidi.io/operations/ama/getMediatorInstancesList',
          ),
        );
}

class AffinidiDidcommGatewayClient {
  final MediatorClient mediatorClient;
  final DidDocument didcommGatewayDidDocument;
  final DidSigner signer;

  AffinidiDidcommGatewayClient({
    required this.mediatorClient,
    required this.didcommGatewayDidDocument,
    required this.signer,
  });

  Future<DidcommMessage> sendMessage(
    PlainTextMessage message, {
    String? accessToken,
  }) async {
    final messageForGateway =
        await DidcommMessage.packIntoSignedAndEncryptedMessages(
      message,
      recipientDidDocuments: [didcommGatewayDidDocument],
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
      // TODO: resolve the key type from didcommGatewayDidDocument
      keyType: KeyType.p256,
      signer: signer,
    );

    final createdTime = DateTime.now().toUtc();
    final expiresTime = createdTime.add(const Duration(seconds: 60));

    final forwardMessage = ForwardMessage(
      id: const Uuid().v4(),
      to: [mediatorClient.mediatorDidDocument.id],
      next: didcommGatewayDidDocument.id,
      expiresTime: expiresTime,
      attachments: [
        Attachment(
          mediaType: 'application/json',
          data: AttachmentData(
            base64: base64UrlEncodeNoPadding(
              messageForGateway.toJsonBytes(),
            ),
          ),
        ),
      ],
    );

    prettyPrint('forwardMessage', object: forwardMessage);

    return await mediatorClient.sendMessage(
      forwardMessage,
      accessToken: accessToken,
    );
  }
}

// {
//   ---- "id": "f800c315-8c75-4efc-9b01-26e1022dbf3b",
//   "typ": "application/didcomm-plain+json",
//   ----  "type": "affinidi.io/operations/ama/getMediatorInstancesList",
//   "body": {},
//   --- "from": "did:peer:2.Vz6Mkpun7xEJWBqwtaiHSqfjLe1ejqQ4PAUEas1gjH7VVNxjs.EzQ3shoprXELvJw9ou4VbfrFRx5FZQsP9EB1LMUJaPacDKtiZ8",
//   --- "to": [
//     "did:web:did.dev.affinidi.io:ama"
//   ],
//   "query_params": {},
//   "headers": {},
//   "path_params": {},
//   --- "created_time": 1754387479,
//   --- "expires_time": 1754387489
// }
