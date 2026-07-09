import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:didcomm/didcomm.dart';
import 'package:path/path.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'example_configs.dart';

const testRetries = 2;

/// How long to keep listening after the expected message(s) have been received
/// to make sure the mediator does not deliver the same message again.
const duplicateDetectionWindow = Duration(seconds: 5);

/// Number of messages used by the tests that verify messages are kept on the
/// mediator when they are not auto-deleted.
const keptMessageCount = 3;

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
        setUpAll(() async {
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

          bobMediatorClient = await MediatorClient.init(
            mediatorDidDocument: bobMediatorDocument,
            didManager: bobDidManager,
            authorizationProvider: await AffinidiAuthorizationProvider.init(
              mediatorDidDocument: bobMediatorDocument,
              didManager: bobDidManager,
            ),
            forwardMessageOptions: const ForwardMessageOptions(
              shouldSign: true,
              keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
              encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
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

          // configure ACL to allow Alice and Bob to communicate via the mediator
          // it is needed only if the mediator requires ACL management
          await Future.wait([
            configureAcl(
              ownDidDocument: aliceDidDocument,
              theirDids: [bobDidDocument.id],
              mediatorClient: aliceMediatorClient,
              expiresTime: DateTime.now().toUtc().add(
                    const Duration(minutes: 3),
                  ),
            ),
            configureAcl(
              ownDidDocument: bobDidDocument,
              theirDids: [aliceDidDocument.id],
              mediatorClient: bobMediatorClient,
              expiresTime: DateTime.now().toUtc().add(
                    const Duration(minutes: 3),
                  ),
            ),
          ]);

          // clear inboxes before tests
          await Future.wait([
            aliceMediatorClient.fetchMessages(),
            bobMediatorClient.fetchMessages(),
          ]);
        });

        tearDown(() async {
          // stop all connections after each test
          // it is need if some tests failed and connections remain open
          await ConnectionPool.instance.stopConnections();
        });

        test('REST API works correctly', () async {
          final expectedBodyContent = const Uuid().v4();

          final alicePlainTextMessage = PlainTextMessage(
            id: const Uuid().v4(),
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
            type: Uri.parse('https://didcomm.org/example/1.0/message'),
            createdTime: DateTime.now().toUtc(),
            body: {'content': expectedBodyContent},
          );

          alicePlainTextMessage['custom-header'] = 'custom-value';

          final aliceSignedAndEncryptedMessage =
              await DidcommMessage.packIntoSignedAndEncryptedMessages(
            alicePlainTextMessage,
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

          expect(
            findDuplicateIds(messageIds),
            isEmpty,
            reason: 'Duplicated message ids in the inbox: '
                '${findDuplicateIds(messageIds)}',
          );

          final messagesFetchedByIds =
              await bobMediatorClient.fetchMessagesByIds(
            messageIds,
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
                  MessageWrappingType.authcryptPlaintext,
                  MessageWrappingType.anoncryptAuthcryptPlaintext,
                ],
              ),
            ),
          );

          final duplicatedUnpackedMessageIds = findDuplicateIds(
            actualUnpackedMessages.map((message) => message.id),
          );

          expect(
            duplicatedUnpackedMessageIds,
            isEmpty,
            reason:
                'Duplicated messages fetched: $duplicatedUnpackedMessageIds',
          );

          final messagesFetchedByCursor = await bobMediatorClient.fetchMessages(
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

          expect(
            actualUnpackedMessages.map((message) => message.id),
            contains(alicePlainTextMessage.id),
            reason: 'Sent message id was not received',
          );
        }, retry: testRetries, tags: []);

        test(
          'REST API keeps messages when they are not auto-deleted',
          () async {
            final sentMessageIds = <String>{};

            for (var i = 0; i < keptMessageCount; i++) {
              final built = await buildForwardMessage(
                senderDidManager: aliceDidManager,
                senderDidDocument: aliceDidDocument,
                recipientDidDocument: bobDidDocument,
                mediatorDidDocument: bobMediatorDocument,
                content: const Uuid().v4(),
              );

              sentMessageIds.add(built.messageId);
              await aliceMediatorClient.sendMessage(built.forwardMessage);
            }

            // fetching without deletion must keep the messages on the mediator
            final firstFetch = await bobMediatorClient.fetchMessages(
              deleteOnMediator: false,
            );

            expect(
              firstFetch.length,
              keptMessageCount,
              reason: 'Expected $keptMessageCount messages, '
                  'but got ${firstFetch.length}',
            );

            final firstFetchIds = await unpackMessageIds(
              firstFetch,
              bobDidManager,
            );

            expect(
              findDuplicateIds(firstFetchIds),
              isEmpty,
              reason: 'Duplicated messages fetched: '
                  '${findDuplicateIds(firstFetchIds)}',
            );

            expect(
              firstFetchIds.toSet(),
              sentMessageIds,
              reason: 'Fetched messages do not match the sent ones',
            );

            // fetching again must return the same messages since none were
            // deleted
            final secondFetch = await bobMediatorClient.fetchMessages(
              deleteOnMediator: false,
            );

            final secondFetchIds = await unpackMessageIds(
              secondFetch,
              bobDidManager,
            );

            expect(
              secondFetchIds.toSet(),
              firstFetchIds.toSet(),
              reason: 'Messages changed between fetches without deletion',
            );

            // finally delete and make sure the inbox is empty
            final messageIds = await bobMediatorClient.listInboxMessageIds();
            await bobMediatorClient.deleteMessages(messageIds: messageIds);

            final inboxAfterDeletion =
                await bobMediatorClient.listInboxMessageIds();

            expect(
              inboxAfterDeletion,
              isEmpty,
              reason: 'Messages were not deleted',
            );
          },
          retry: testRetries,
        );

        test(
          'WebSockets API works correctly',
          () async {
            final expectedBodyContent = const Uuid().v4();

            final alicePlainTextMessage = PlainTextMessage(
              id: const Uuid().v4(),
              from: aliceDidDocument.id,
              to: [bobDidDocument.id],
              type: Uri.parse('https://didcomm.org/example/1.0/message'),
              body: {'content': expectedBodyContent},
            );

            alicePlainTextMessage['custom-header'] = 'custom-value';

            final aliceSignedAndEncryptedMessage =
                await DidcommMessage.packIntoSignedAndEncryptedMessages(
              alicePlainTextMessage,
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

            final receivedMessageIds = <String>{};
            final duplicateMessageIds = <String>[];

            final expectedMessagesReceived = Completer<void>();

            bobMediatorClient.listenForIncomingMessages(
              (message) async {
                final encryptedMessage = EncryptedMessage.fromJson(message);
                final senderDid = const JweHeaderConverter()
                    .fromJson(encryptedMessage.protected)
                    .subjectKeyId;

                final isMediatorTelemetryMessage = isMediatorDid(senderDid);

                final unpackedMessage =
                    await DidcommMessage.unpackToPlainTextMessage(
                  message: message,
                  recipientDidManager: bobDidManager,
                  validateAddressingConsistency: true,
                  expectedMessageWrappingTypes: isMediatorTelemetryMessage
                      ? [
                          // send by the old mediator
                          // TODO: remove after migration to the new mediator is completed
                          MessageWrappingType.authcryptSignPlaintext,
                          // send by the new mediator
                          MessageWrappingType.authcryptPlaintext
                        ]
                      : [
                          MessageWrappingType.anoncryptSignPlaintext,
                        ],
                  expectedSigners: isMediatorTelemetryMessage
                      ? null
                      : [
                          aliceDidDocument.assertionMethod.first.didKeyId,
                        ],
                );

                // track received message ids to detect duplicated messages
                if (!receivedMessageIds.add(unpackedMessage.id)) {
                  duplicateMessageIds.add(unpackedMessage.id);
                }

                if (isMediatorTelemetryMessage) {
                  telemetryMessageReceived = true;
                } else {
                  actualBodyContent ??=
                      unpackedMessage.body?['content'] as String?;
                }

                if (actualBodyContent == expectedBodyContent &&
                    telemetryMessageReceived == true &&
                    !expectedMessagesReceived.isCompleted) {
                  expectedMessagesReceived.complete();
                }
              },
              onError: (Object error) => prettyPrint('error', object: error),
              cancelOnError: false,
            );

            await ConnectionPool.instance.startConnections();

            await aliceMediatorClient.sendMessage(
              forwardMessage,
            );

            await expectedMessagesReceived.future;

            // keep the connection open for a while to make sure the expected
            // message is not delivered again (no duplicated messages)
            await Future<void>.delayed(duplicateDetectionWindow);

            await ConnectionPool.instance.stopConnections();

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

            expect(
              receivedMessageIds,
              contains(alicePlainTextMessage.id),
              reason: 'Sent message id was not received',
            );

            expect(
              duplicateMessageIds,
              isEmpty,
              reason: 'Duplicated messages received: $duplicateMessageIds',
            );
          },
          retry: testRetries,
        );

        test(
          'WebSockets API keeps messages when they are not auto-deleted',
          () async {
            // a dedicated client that does not delete messages on receive,
            // so they remain available on the mediator after being delivered
            final bobKeepMessagesClient = await MediatorClient.init(
              mediatorDidDocument: bobMediatorDocument,
              didManager: bobDidManager,
              authorizationProvider: await AffinidiAuthorizationProvider.init(
                mediatorDidDocument: bobMediatorDocument,
                didManager: bobDidManager,
              ),
              forwardMessageOptions: const ForwardMessageOptions(
                shouldSign: true,
                keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
                encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
              ),
              webSocketOptions: const WebSocketOptions(
                deleteOnReceive: false,
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

            final sentMessageIds = <String>{};
            final forwardMessages = <ForwardMessage>[];
            final receivedMessageIds = <String>{};
            final duplicateMessageIds = <String>[];
            final allMessagesReceived = Completer<void>();

            // build the messages up front so [sentMessageIds] is fully
            // populated before the listener evaluates its completion condition
            for (var i = 0; i < keptMessageCount; i++) {
              final built = await buildForwardMessage(
                senderDidManager: aliceDidManager,
                senderDidDocument: aliceDidDocument,
                recipientDidDocument: bobDidDocument,
                mediatorDidDocument: bobMediatorDocument,
                content: const Uuid().v4(),
              );

              sentMessageIds.add(built.messageId);
              forwardMessages.add(built.forwardMessage);
            }

            bobKeepMessagesClient.listenForIncomingMessages(
              (message) async {
                final encryptedMessage = EncryptedMessage.fromJson(message);
                final senderDid = const JweHeaderConverter()
                    .fromJson(encryptedMessage.protected)
                    .subjectKeyId;

                // ignore mediator telemetry messages
                if (isMediatorDid(senderDid)) {
                  return;
                }

                final unpackedMessage =
                    await DidcommMessage.unpackToPlainTextMessage(
                  message: message,
                  recipientDidManager: bobDidManager,
                  validateAddressingConsistency: true,
                  expectedMessageWrappingTypes: [
                    MessageWrappingType.anoncryptSignPlaintext,
                  ],
                  expectedSigners: [
                    aliceDidDocument.assertionMethod.first.didKeyId,
                  ],
                );

                // track received message ids to detect duplicated messages
                if (!receivedMessageIds.add(unpackedMessage.id)) {
                  duplicateMessageIds.add(unpackedMessage.id);
                }

                if (sentMessageIds.every(receivedMessageIds.contains) &&
                    !allMessagesReceived.isCompleted) {
                  allMessagesReceived.complete();
                }
              },
              onError: (Object error) => prettyPrint('error', object: error),
              cancelOnError: false,
            );

            await ConnectionPool.instance.startConnections();

            // send after the connection is established so each message is
            // pushed via live delivery while also remaining in the inbox
            // (deleteOnReceive: false) - the scenario where the live-delivery
            // and inbox-drain paths could otherwise emit the same message twice
            for (final forwardMessage in forwardMessages) {
              await aliceMediatorClient.sendMessage(forwardMessage);
            }

            await allMessagesReceived.future;

            // keep the connection open for a while to make sure the same
            // messages are not delivered again (no duplicated messages)
            await Future<void>.delayed(duplicateDetectionWindow);

            await ConnectionPool.instance.stopConnections();

            expect(
              duplicateMessageIds,
              isEmpty,
              reason: 'Duplicated messages received: $duplicateMessageIds',
            );

            expect(
              receivedMessageIds,
              sentMessageIds,
              reason: 'Received messages do not match the sent ones',
            );

            // since deleteOnReceive is false, the messages must still be
            // available on the mediator after being delivered
            final remainingMessages = await bobKeepMessagesClient.fetchMessages(
              deleteOnMediator: false,
            );

            expect(
              remainingMessages.length,
              keptMessageCount,
              reason: 'Expected $keptMessageCount messages to be kept on the '
                  'mediator, but got ${remainingMessages.length}',
            );

            final remainingIds = await unpackMessageIds(
              remainingMessages,
              bobDidManager,
            );

            expect(
              findDuplicateIds(remainingIds),
              isEmpty,
              reason: 'Duplicated messages kept on the mediator: '
                  '${findDuplicateIds(remainingIds)}',
            );

            expect(
              remainingIds.toSet(),
              sentMessageIds,
              reason: 'Kept messages differ from the sent ones',
            );

            // clean up the inbox for the following tests
            final inboxIds = await bobKeepMessagesClient.listInboxMessageIds();
            await bobKeepMessagesClient.deleteMessages(messageIds: inboxIds);
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

        test('Can connect after connections have been started', () async {
          final aliceCompleter = Completer<PlainTextMessage>();
          final bobCompleter = Completer<PlainTextMessage>();

          final aliceReceivedMessageIds = <String>{};
          final bobReceivedMessageIds = <String>{};
          final duplicateMessageIds = <String>[];

          final alicePlainTextMessage = PlainTextMessage(
            id: const Uuid().v4(),
            from: aliceDidDocument.id,
            to: [bobDidDocument.id],
            type: Uri.parse('https://didcomm.org/example/1.0/message'),
          );

          final bobPlainTextMessage = PlainTextMessage(
            id: const Uuid().v4(),
            from: bobDidDocument.id,
            to: [aliceDidDocument.id],
            type: Uri.parse('https://didcomm.org/example/1.0/message'),
          );

          final encryptedAliceMessage =
              await DidcommMessage.packIntoSignedAndEncryptedMessages(
            alicePlainTextMessage,
            keyType: [bobDidDocument].getCommonKeyTypesInKeyAgreements().first,
            recipientDidDocuments: [bobDidDocument],
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
            encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
            signer: await aliceDidManager.getSigner(
              aliceDidDocument.assertionMethod.first.id,
            ),
          );

          final encryptedBobMessage =
              await DidcommMessage.packIntoSignedAndEncryptedMessages(
            bobPlainTextMessage,
            keyType:
                [aliceDidDocument].getCommonKeyTypesInKeyAgreements().first,
            recipientDidDocuments: [aliceDidDocument],
            keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
            encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
            signer: await bobDidManager.getSigner(
              bobDidDocument.assertionMethod.first.id,
            ),
          );

          // Alice sends message to Bob and Bob receives it

          await aliceMediatorClient.sendMessage(
            ForwardMessage(
              id: const Uuid().v4(),
              from: aliceDidDocument.id,
              to: [bobMediatorDocument.id],
              next: alicePlainTextMessage.to!.first,
              attachments: [
                Attachment(
                  mediaType: 'application/json',
                  data: AttachmentData(
                    base64: base64UrlEncodeNoPadding(
                      encryptedAliceMessage.toJsonBytes(),
                    ),
                  ),
                ),
              ],
            ),
          );

          bobMediatorClient.listenForIncomingMessages(
            (message) async {
              final unpacked = await DidcommMessage.unpackToPlainTextMessage(
                message: message,
                recipientDidManager: bobDidManager,
                expectedMessageWrappingTypes: [
                  MessageWrappingType.anoncryptSignPlaintext,
                  MessageWrappingType.authcryptSignPlaintext,
                  MessageWrappingType.authcryptPlaintext,
                  MessageWrappingType.anoncryptAuthcryptPlaintext,
                ],
              );

              if (isMediatorDid(unpacked.from)) {
                return;
              }

              // track received message ids to detect duplicated messages
              if (!bobReceivedMessageIds.add(unpacked.id)) {
                duplicateMessageIds.add(unpacked.id);
              }

              // intentionally not guarding with isCompleted so a duplicated
              // message fails the test by completing the completer twice
              bobCompleter.complete(unpacked);
            },
            onError: (Object error) async {
              aliceCompleter.completeError(error);
              await ConnectionPool.instance.stopConnections();
            },
            onDone: ({closeCode, closeReason}) {
              if (!bobCompleter.isCompleted) {
                bobCompleter.completeError(
                  Exception(
                    'WebSocket closed unexpectedly. Code: $closeCode, Reason: $closeReason',
                  ),
                );
              }
            },
          );

          await ConnectionPool.instance.startConnections();

          // Bob sends message to Alice and Alice receives it

          await bobMediatorClient.sendMessage(
            ForwardMessage(
              id: const Uuid().v4(),
              from: bobDidDocument.id,
              to: [bobMediatorDocument.id],
              next: bobPlainTextMessage.to!.first,
              attachments: [
                Attachment(
                  mediaType: 'application/json',
                  data: AttachmentData(
                    base64: base64UrlEncodeNoPadding(
                      encryptedBobMessage.toJsonBytes(),
                    ),
                  ),
                ),
              ],
            ),
          );

          aliceMediatorClient.listenForIncomingMessages(
            (message) async {
              final unpacked = await DidcommMessage.unpackToPlainTextMessage(
                message: message,
                recipientDidManager: aliceDidManager,
                expectedMessageWrappingTypes: [
                  MessageWrappingType.anoncryptSignPlaintext,
                  MessageWrappingType.authcryptSignPlaintext,
                  MessageWrappingType.authcryptPlaintext,
                  MessageWrappingType.anoncryptAuthcryptPlaintext,
                ],
              );

              if (isMediatorDid(unpacked.from)) {
                return;
              }

              // track received message ids to detect duplicated messages
              if (!aliceReceivedMessageIds.add(unpacked.id)) {
                duplicateMessageIds.add(unpacked.id);
              }

              // intentionally not guarding with isCompleted so a duplicated
              // message fails the test by completing the completer twice
              aliceCompleter.complete(unpacked);
            },
            onError: (Object error) async {
              aliceCompleter.completeError(error);
              await ConnectionPool.instance.stopConnections();
            },
            onDone: ({closeCode, closeReason}) async {
              if (!aliceCompleter.isCompleted) {
                aliceCompleter.completeError(
                  Exception(
                    'WebSocket closed unexpectedly. Code: $closeCode, Reason: $closeReason',
                  ),
                );

                await ConnectionPool.instance.stopConnections();
              }
            },
          );

          await ConnectionPool.instance.startConnections();

          final receivedAliceMessage = await aliceCompleter.future;
          final receivedBobMessage = await bobCompleter.future;

          // keep the connections open for a while to make sure the mediator
          // does not deliver the same messages again (no duplicated messages)
          await Future<void>.delayed(duplicateDetectionWindow);

          await ConnectionPool.instance.stopConnections();

          expect(
            receivedBobMessage.id,
            alicePlainTextMessage.id,
            reason: 'Alice did not receive the expected message from Bob',
          );

          expect(
            receivedAliceMessage.id,
            bobPlainTextMessage.id,
            reason: 'Bob did not receive the expected message from Alice',
          );

          expect(
            duplicateMessageIds,
            isEmpty,
            reason: 'Duplicated messages received: $duplicateMessageIds',
          );
        });
      });
    }

    test(
      'Running example files to check if they are aligned with the code',
      () async {
        final exampleDirectory = Directory(
          join(
            Directory.current.path,
            'example',
          ),
        );

        if (!await exampleDirectory.exists()) {
          failTest('No example directory found.');
        }

        final dartFiles = exampleDirectory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList();

        if (dartFiles.isEmpty) {
          failTest('No Dart example files found.');
        }

        final filesWithMain = <File>[];

        for (final file in dartFiles) {
          final content = await file.readAsString();
          if (content.contains('void main()')) {
            filesWithMain.add(file);
          }
        }

        if (filesWithMain.isEmpty) {
          failTest('No Dart example files with void main() found.');
          return;
        }

        final errors = <String>[];

        for (final file in filesWithMain) {
          final result = await Process.run(
            Platform.resolvedExecutable,
            [file.path],
            runInShell: true,
          );

          if (result.exitCode != 0) {
            errors.add(
              'FAILED: ${file.path}.\nExit code: ${result.exitCode}.\nStdout: ${result.stdout}.\nStderr: ${result.stderr}.',
            );
          }
        }

        if (errors.isNotEmpty) {
          failTest(errors.join('\n'));
        }

        expect(errors, isEmpty);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

void failTest(String message) {
  throw Exception(message);
}

/// Returns the ids that appear more than once in [ids], preserving the order
/// in which the duplicates are encountered.
List<String> findDuplicateIds(Iterable<String> ids) {
  final seen = <String>{};
  final duplicates = <String>[];

  for (final id in ids) {
    if (!seen.add(id)) {
      duplicates.add(id);
    }
  }

  return duplicates;
}

/// Packs [content] into a signed and encrypted message and wraps it into a
/// [ForwardMessage] addressed to the recipient's mediator.
///
/// Returns the forward message together with the id of the inner plaintext
/// message so callers can correlate what was sent with what is received.
Future<({ForwardMessage forwardMessage, String messageId})>
    buildForwardMessage({
  required DidManager senderDidManager,
  required DidDocument senderDidDocument,
  required DidDocument recipientDidDocument,
  required DidDocument mediatorDidDocument,
  required String content,
}) async {
  final messageId = const Uuid().v4();

  final plainTextMessage = PlainTextMessage(
    id: messageId,
    from: senderDidDocument.id,
    to: [recipientDidDocument.id],
    type: Uri.parse('https://didcomm.org/example/1.0/message'),
    body: {'content': content},
  );

  final signedAndEncryptedMessage =
      await DidcommMessage.packIntoSignedAndEncryptedMessages(
    plainTextMessage,
    keyType: [recipientDidDocument].getCommonKeyTypesInKeyAgreements().first,
    recipientDidDocuments: [recipientDidDocument],
    keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdhEs,
    encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    signer: await senderDidManager.getSigner(
      senderDidDocument.assertionMethod.first.id,
    ),
  );

  final forwardMessage = ForwardMessage(
    id: const Uuid().v4(),
    from: senderDidDocument.id,
    to: [mediatorDidDocument.id],
    next: recipientDidDocument.id,
    expiresTime: DateTime.now().toUtc().add(const Duration(seconds: 600)),
    attachments: [
      Attachment(
        mediaType: 'application/json',
        data: AttachmentData(
          base64: base64UrlEncodeNoPadding(
            signedAndEncryptedMessage.toJsonBytes(),
          ),
        ),
      ),
    ],
  );

  return (forwardMessage: forwardMessage, messageId: messageId);
}

/// Unpacks [messages] and returns their DIDComm message ids.
Future<List<String>> unpackMessageIds(
  List<Map<String, dynamic>> messages,
  DidManager recipientDidManager,
) async {
  final unpackedMessages = await Future.wait(
    messages.map(
      (message) => DidcommMessage.unpackToPlainTextMessage(
        message: message,
        recipientDidManager: recipientDidManager,
        expectedMessageWrappingTypes: [
          MessageWrappingType.anoncryptSignPlaintext,
          MessageWrappingType.authcryptSignPlaintext,
          MessageWrappingType.authcryptPlaintext,
          MessageWrappingType.anoncryptAuthcryptPlaintext,
        ],
      ),
    ),
  );

  return unpackedMessages.map((message) => message.id).toList();
}

/// Whether [did] belongs to the mediator (used to identify mediator-originated
/// messages such as telemetry).
bool isMediatorDid(String? did) => did?.contains('.affinidi.io') == true;
