import 'dart:async';

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
    super.body = const {},
  }) : super(
          type: Uri.parse(
            'affinidi.io/operations/ama/getMediatorInstancesList',
          ),
        );
}

class AffinidiDidcommGatewayClient {
  final MediatorClient mediatorClient;
  final DidManager didManager;
  final DidDocument didcommGatewayDidDocument;
  final DidSigner signer;
  final KeyPair keyPair;
  final String didKeyId;

  AffinidiDidcommGatewayClient({
    required this.mediatorClient,
    required this.didManager,
    required this.didcommGatewayDidDocument,
    required this.signer,
    required this.keyPair,
    required this.didKeyId,
  });

  Future<PlainTextMessage> getMediators({
    required String accessToken,
  }) async {
    final getMediatorsMessage = GetMediatorInstancesListMessage(
      id: const Uuid().v4(),
      from: signer.did,
      to: [didcommGatewayDidDocument.id],
      createdTime: DateTime.now().toUtc(),
      expiresTime: DateTime.now().add(const Duration(minutes: 5)).toUtc(),
    );

    prettyPrint(
      'GetMediatorInstancesListMessage for DIDComm Gateway',
      object: getMediatorsMessage,
    );

    final messageForGateway =
        await DidcommMessage.packIntoSignedAndEncryptedMessages(
      getMediatorsMessage,
      // FIXME
      recipientDidDocuments: [
        didcommGatewayDidDocument,
      ],
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
      // TODO: resolve the key type from didcommGatewayDidDocument
      keyPair: keyPair,
      didKeyId: didKeyId,
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

    final completer = Completer<PlainTextMessage>();

    await mediatorClient.listenForIncomingMessages(
      (message) async {
        final unpackedMessage = await DidcommMessage.unpackToPlainTextMessage(
          message: message,
          recipientDidManager: didManager,
          expectedMessageWrappingTypes: [
            MessageWrappingType.authcryptSignPlaintext,
            MessageWrappingType.anoncryptSignPlaintext,
          ],
        );

        if (unpackedMessage.type.toString() ==
            '${getMediatorsMessage.type.toString()}/response') {
          await mediatorClient.disconnect();
          completer.complete(unpackedMessage);
        }
      },
      onError: completer.completeError,
      accessToken: accessToken,
      cancelOnError: false,
    );

    await mediatorClient.sendMessage(
      forwardMessage,
      accessToken: accessToken,
    );

    return completer.future;
  }
}
