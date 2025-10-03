import 'dart:async';

import 'package:collection/collection.dart';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'example_configs.dart';

const testRetries = 2;

void main() async {
  await configureTestFiles();

  group('Mediator Integration Test', () {
    late PersistentWallet aliceWallet;
    late DidManager aliceDidManager;
    late DidDocument aliceDidDocument;
    late MediatorClient aliceMediatorClient;

    late PersistentWallet bobWallet;
    late DidManager bobDidManager;
    late DidDocument bobDidDocument;
    late MediatorClient bobMediatorClient;

    late DidDocument bobMediatorDocument;

    for (final didType in [
      'did:key',
      'did:peer',
    ]) {
      group(didType, () {
        setUp(() async {
          final useDidKey = didType == 'did:key';

          final aliceKeyStore = InMemoryKeyStore();
          aliceWallet = PersistentWallet(aliceKeyStore);

          if (useDidKey) {
            aliceDidManager = DidKeyManager(
              wallet: aliceWallet,
              store: InMemoryDidStore(),
            );
          } else {
            aliceDidManager = DidPeerManager(
              wallet: aliceWallet,
              store: InMemoryDidStore(),
            );
          }

          final bobKeyStore = InMemoryKeyStore();
          bobWallet = PersistentWallet(bobKeyStore);

          if (useDidKey) {
            bobDidManager = DidKeyManager(
              wallet: bobWallet,
              store: InMemoryDidStore(),
            );
          } else {
            bobDidManager = DidPeerManager(
              wallet: bobWallet,
              store: InMemoryDidStore(),
            );
          }

          final aliceKeyId = 'alice-key-1';
          final alicePrivateKeyBytes = await extractPrivateKeyBytes(
            alicePrivateKeyPath,
          );

          await aliceKeyStore.set(
            aliceKeyId,
            StoredKey(
              keyType: KeyType.p256,
              privateKeyBytes: alicePrivateKeyBytes,
            ),
          );

          await aliceDidManager.addVerificationMethod(aliceKeyId);
          aliceDidDocument = await aliceDidManager.getDidDocument();

          final bobKeyId = 'bob-key-1';
          final bobPrivateKeyBytes = await extractPrivateKeyBytes(
            bobPrivateKeyPath,
          );

          await bobKeyStore.set(
            bobKeyId,
            StoredKey(
              keyType: KeyType.p256,
              privateKeyBytes: bobPrivateKeyBytes,
            ),
          );

          await bobDidManager.addVerificationMethod(bobKeyId);
          bobDidDocument = await bobDidManager.getDidDocument();

          bobMediatorDocument =
              await UniversalDIDResolver.defaultResolver.resolveDid(
            await readDid(mediatorDidPath),
          );

          aliceMediatorClient = await MediatorClient.init(
            didManager: aliceDidManager,
            mediatorDidDocument: bobMediatorDocument,
            authorizationProvider: await AffinidiAuthorizationProvider.init(
              didManager: aliceDidManager,
              mediatorDidDocument: bobMediatorDocument,
            ),
            forwardMessageOptions: const ForwardMessageOptions(
              shouldSign: true,
              keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
              encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
            ),
          );

          bobMediatorClient = await MediatorClient.init(
            mediatorDidDocument: bobMediatorDocument,
            didManager: bobDidManager,
            authorizationProvider: await AffinidiAuthorizationProvider.init(
              mediatorDidDocument: bobMediatorDocument,
              didManager: bobDidManager,
            ),
            webSocketOptions: const WebSocketOptions(
              liveDeliveryChangeMessageOptions:
                  LiveDeliveryChangeMessageOptions(
                shouldSend: true,
                shouldSign: true,
                keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
                encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
              ),
              statusRequestMessageOptions: StatusRequestMessageOptions(
                shouldSend: true,
                shouldSign: true,
                keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
                encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
              ),
            ),
          );
        });

        test('REST API works correctly', () async {
          final expectedBodyContent = const Uuid().v4();

          final alicePlainTextMassage = PlainTextMessage(
            id: const Uuid().v4(),
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
            type: Uri.parse('https://didcomm.org/example/1.0/message'),
            createdTime: DateTime.now().toUtc(),
            body: {'content': expectedBodyContent},
            createdTime: DateTime.now().toUtc(),
          );

          alicePlainTextMassage['custom-header'] = 'custom-value';

          final aliceSignedAndEncryptedMessage =
              await DidcommMessage.packIntoSignedAndEncryptedMessages(
            alicePlainTextMassage,
            keyType: [bobDidDocument].getCommonKeyTypesInKeyAgreements().first,
            recipientDidDocuments: [bobDidDocument],
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
            encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
            signer: await aliceDidManager.getSigner(
              aliceDidDocument.assertionMethod.first.id,
            ),
          );

          final createdTime = DateTime.now().toUtc();
          final expiresTime = createdTime.add(const Duration(seconds: 60));

          final forwardMessage = ForwardMessage(
            id: const Uuid().v4(),
            to: [bobMediatorDocument.id],
            from: aliceDidDocument.id,
            next: bobDidDocument.id,
            expiresTime: expiresTime,
            attachments: [
              Attachment(
                mediaType: 'application/json',
                data: AttachmentData(
                  base64: base64UrlEncodeNoPadding(
                    aliceSignedAndEncryptedMessage.toJsonBytes(),
                  ),
                ),
              ),
            ],
          );

          await aliceMediatorClient.sendMessage(
            forwardMessage,
          );

          final messageIds = await bobMediatorClient.listInboxMessageIds();

          final messagesFetchedByIds = await bobMediatorClient.fetchMessages(
            messageIds: messageIds,
            deleteOnMediator: false,
          );

          final actualUnpackedMessages = await Future.wait(
            messagesFetchedByIds.map(
              (message) => DidcommMessage.unpackToPlainTextMessage(
                message: message,
                recipientDidManager: bobDidManager,
                validateAddressingConsistency: true,
                expectedMessageWrappingTypes: [
                  MessageWrappingType.anoncryptSignPlaintext,
                  MessageWrappingType.authcryptSignPlaintext,
                ],
                expectedSigners: [
                  aliceDidDocument.assertionMethod.first.didKeyId,
                ],
              ),
            ),
          );

          final messagesFetchedByCursor =
              await bobMediatorClient.fetchMessagesStartingFrom(
            startFrom: actualUnpackedMessages.first.createdTime,
            deleteOnMediator: false,
          );

          await bobMediatorClient.deleteMessages(
            messageIds: messageIds,
          );

          final messagesAfterDeletion =
              await bobMediatorClient.listInboxMessageIds();

          expect(
            messagesFetchedByIds.isNotEmpty,
            isTrue,
            reason: 'No messages fetched',
          );

          expect(
            messagesAfterDeletion.isEmpty,
            isTrue,
            reason: 'Messages were not deleted',
          );

          expect(
            messagesFetchedByIds.length,
            messagesFetchedByCursor.length,
            reason:
                'Messages fetched by IDs and by cursor have different lengths',
          );

          expect(
            messagesFetchedByIds.length,
            1,
            reason:
                'Expected exactly one message, but found ${messagesFetchedByIds.length}',
          );

          final actualBodyContents = actualUnpackedMessages
              .map<String?>((message) => message.body?['content'] as String)
              .toList();

          expect(
            actualBodyContents.singleWhereOrNull(
              (content) => content == expectedBodyContent,
            ),
            isNotNull,
            reason: 'Sent message not found',
          );
        }, retry: testRetries, tags: []);

        test(
          'WebSockets API works correctly',
          () async {
            final expectedBodyContent = const Uuid().v4();

            final alicePlainTextMassage = PlainTextMessage(
              id: const Uuid().v4(),
              from: aliceDidDocument.id,
              to: [bobDidDocument.id],
              type: Uri.parse('https://didcomm.org/example/1.0/message'),
              body: {'content': expectedBodyContent},
            );

            alicePlainTextMassage['custom-header'] = 'custom-value';

            final aliceSignedAndEncryptedMessage =
                await DidcommMessage.packIntoSignedAndEncryptedMessages(
              alicePlainTextMassage,
              keyType: [
                bobDidDocument,
              ].getCommonKeyTypesInKeyAgreements().first,
              recipientDidDocuments: [bobDidDocument],
              keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
              encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
              signer: await aliceDidManager.getSigner(
                aliceDidDocument.assertionMethod.first.id,
              ),
            );

            final createdTime = DateTime.now().toUtc();
            final expiresTime = createdTime.add(const Duration(seconds: 60));

            final forwardMessage = ForwardMessage(
              id: const Uuid().v4(),
              to: [bobMediatorDocument.id],
              from: aliceDidDocument.id,
              next: bobDidDocument.id,
              expiresTime: expiresTime,
              attachments: [
                Attachment(
                  mediaType: 'application/json',
                  data: AttachmentData(
                    base64: base64UrlEncodeNoPadding(
                      aliceSignedAndEncryptedMessage.toJsonBytes(),
                    ),
                  ),
                ),
              ],
            );

            String? actualBodyContent;
            bool? telemetryMessageReceived;

            final completer = Completer<void>();

            await bobMediatorClient.listenForIncomingMessages(
              (message) async {
                final encryptedMessage = EncryptedMessage.fromJson(message);
                final senderDid = const JweHeaderConverter()
                    .fromJson(encryptedMessage.protected)
                    .subjectKeyId;

                final isMediatorTelemetryMessage =
                    senderDid?.contains('.affinidi.io') == true;

                final unpackedMessage =
                    await DidcommMessage.unpackToPlainTextMessage(
                  message: message,
                  recipientDidManager: bobDidManager,
                  validateAddressingConsistency: true,
                  expectedMessageWrappingTypes: [
                    isMediatorTelemetryMessage
                        ? MessageWrappingType.authcryptSignPlaintext
                        : MessageWrappingType.anoncryptSignPlaintext,
                  ],
                  expectedSigners: [
                    isMediatorTelemetryMessage
                        ? bobMediatorDocument.assertionMethod.first.didKeyId
                        : aliceDidDocument.assertionMethod.first.didKeyId,
                  ],
                );

                if (isMediatorTelemetryMessage) {
                  telemetryMessageReceived = true;
                } else {
                  actualBodyContent ??=
                      unpackedMessage.body?['content'] as String?;
                }

                if (actualBodyContent == expectedBodyContent &&
                    telemetryMessageReceived == true) {
                  await bobMediatorClient.disconnect();
                  completer.complete();
                }
              },
              onError: (Object error) => prettyPrint('error', object: error),
              cancelOnError: false,
            );

            await aliceMediatorClient.sendMessage(
              forwardMessage,
            );

            await completer.future;

            expect(
              actualBodyContent,
              expectedBodyContent,
              reason: 'Sent message not found',
            );

            expect(
              telemetryMessageReceived,
              isTrue,
              reason: 'No telemetry message',
            );
          },
          retry: testRetries,
        );

        test('OOB API works correctly', () async {
          final message = OutOfBandMessage(
            id: const Uuid().v4(),
            from: aliceDidDocument.id,
            body: {
              'goal_code': 'connect',
              'goal': 'Start relationship',
              'accept': ['didcomm/v2'],
            },
          );

          final oobId = await aliceMediatorClient.createOob(
            message,
          );

          expect(oobId, isNotEmpty);
        });
      });
    }
  });
}
