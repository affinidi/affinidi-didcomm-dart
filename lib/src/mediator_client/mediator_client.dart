import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import '../../didcomm.dart';
import 'connection.dart';

part 'connection_pool.dart';

/// Client for interacting with a DIDComm mediator, supporting message sending, inbox management,
/// and real-time message delivery via WebSockets.
class MediatorClient {
  /// The DID Document of the mediator.
  final DidDocument mediatorDidDocument;

  /// The key pair used for encryption and signing.
  final KeyPair keyPair;

  /// The key ID used for encryption.
  final String didKeyId;

  /// The signer used for signing messages.
  final DidSigner signer;

  /// Maintains a pool of WebSocket [Connection]s shared across multiple [MediatorClient]s,
  /// enabling concurrent usage and efficient reuse of existing connections.
  final ConnectionPool connectionPool;

  /// Options for forwarding messages to the mediator.
  final ForwardMessageOptions forwardMessageOptions;

  /// Options for WebSocket connections.
  final WebSocketOptions webSocketOptions;

  /// Optional provider for authorization tokens.
  final AuthorizationProvider? authorizationProvider;

  final Dio _dio;

  /// Creates a [MediatorClient] instance.
  ///
  /// [mediatorDidDocument] - The mediator's DID Document.
  /// [keyPair] - The key pair for encryption/signing.
  /// [didKeyId] - The key ID for encryption.
  /// [signer] - The signer for signing messages.
  /// [forwardMessageOptions] - Options for forwarding messages (default: const ForwardMessageOptions()).
  /// [webSocketOptions] - Options for WebSocket/live delivery (default: const WebSocketOptions()).
  MediatorClient({
    required this.mediatorDidDocument,
    required this.keyPair,
    required this.didKeyId,
    required this.signer,
    ConnectionPool? connectionPool,
    this.authorizationProvider,
    this.forwardMessageOptions = const ForwardMessageOptions(),
    this.webSocketOptions = const WebSocketOptions(),
  })  : _dio = mediatorDidDocument.toDio(
          mediatorServiceType: DidDocumentServiceType.didCommMessaging,
        ),
        connectionPool = connectionPool ?? ConnectionPool.instance;

  /// Initializes a [MediatorClient] by resolving the appropriate key agreement and signer
  /// from the provided [DidManager] and [mediatorDidDocument].
  ///
  /// Throws an [Exception] if no suitable key is found for key agreement with the mediator.
  ///
  /// [mediatorDidDocument] - The mediator's DID Document.
  /// [didManager] - The DID manager for resolving keys and signers.
  /// [authorizationProvider] - Provider for authorization tokens (optional).
  /// [forwardMessageOptions] - Options for forwarding messages (default: const ForwardMessageOptions()).
  /// [webSocketOptions] - Options for WebSocket/live delivery (default: const WebSocketOptions()).
  static Future<MediatorClient> init({
    required DidDocument mediatorDidDocument,
    required DidManager didManager,
    AuthorizationProvider? authorizationProvider,
    ForwardMessageOptions forwardMessageOptions = const ForwardMessageOptions(),
    WebSocketOptions webSocketOptions = const WebSocketOptions(),
  }) async {
    final ownDidDocument = await didManager.getDidDocument();

    final matchedDidKeyIds = ownDidDocument.matchKeysInKeyAgreement(
      otherDidDocuments: [
        mediatorDidDocument,
      ],
    );

    if (matchedDidKeyIds.isEmpty) {
      throw Exception(
        'No suitable key found for key agreement with the mediator.',
      );
    }

    final didKeyId = matchedDidKeyIds.first;

    return MediatorClient(
      authorizationProvider: authorizationProvider,
      mediatorDidDocument: mediatorDidDocument,
      keyPair: await didManager.getKeyPairByDidKeyId(
        didKeyId,
      ),
      didKeyId: didKeyId,
      signer: await didManager.getSigner(
        ownDidDocument.authentication.first.id,
      ),
      forwardMessageOptions: forwardMessageOptions,
      webSocketOptions: webSocketOptions,
    );
  }

  /// Creates a [MediatorClient] from a mediator DID Document URI.
  ///
  /// [didDocumentUrl] - The URI of the mediator's DID Document.
  /// [keyPair] - The key pair for encryption/signing.
  /// [didKeyId] - The key ID for encryption.
  /// [signer] - The signer for signing messages.
  static Future<MediatorClient> fromMediatorDidDocumentUri(
    Uri didDocumentUrl, {
    required KeyPair keyPair,
    required String didKeyId,
    required DidSigner signer,
  }) async {
    return MediatorClient(
      mediatorDidDocument:
          await UniversalDIDResolver.defaultResolver.resolveDid(
        didDocumentUrl.toString(),
      ),
      keyPair: keyPair,
      didKeyId: didKeyId,
      signer: signer,
    );
  }

  /// Sends a [ForwardMessage] to the mediator.
  ///
  /// [message] - The message to send.
  ///
  /// Returns the packed [DidcommMessage] that was sent.
  Future<DidcommMessage> sendMessage(ForwardMessage message) async {
    final messageToSend = await packMessage(
      message,
      messageOptions: forwardMessageOptions,
    );

    try {
      await _dio.post<Map<String, dynamic>>(
        '/inbound',
        data: messageToSend,
        options: Options(headers: await getAuthorizationHeaders()),
      );

      return messageToSend;
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }

  /// Lists message IDs in the inbox for the current actor.
  ///
  /// Returns a list of message IDs as strings.
  Future<List<String>> listInboxMessageIds() async {
    final did = getDidFromId(didKeyId);

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/list/${sha256.convert(utf8.encode(did)).toString()}/inbox',
        options: Options(headers: await getAuthorizationHeaders()),
      );

      return (response.data!['data'] as List<dynamic>)
          .map(
            (item) => (item as Map<String, dynamic>)['msg_id'] as String,
          )
          .toList();
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }

  /// Fetches outbound messages from the mediator by message IDs.
  ///
  /// [messageIds] - The list of message IDs to fetch.
  /// [deleteOnMediator] - Whether to delete messages from the mediator after fetching (default: true).
  ///
  /// Returns a list of messages.
  Future<List<Map<String, dynamic>>> fetchMessagesByIds(
    List<String> messageIds, {
    bool deleteOnMediator = true,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/outbound',
        data: {'message_ids': messageIds, 'delete': deleteOnMediator},
        options: Options(headers: await getAuthorizationHeaders()),
      );

      return _responseToMessages(response);
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }

  /// Fetches outbound messages from the mediator pointing the starting date.
  ///
  /// [startFrom] - The starting point to fetch messages from date (inclusive). If null, fetches from the beginning.
  /// [batchSize] - Number of messages to fetch at once (default: 25).
  /// [deleteOnMediator] - Whether to delete messages from the mediator after fetching (default: true).
  ///
  /// Returns a list of messages.
  Future<List<Map<String, dynamic>>> fetchMessages({
    DateTime? startFrom,
    int? batchSize = 25,
    bool deleteOnMediator = true,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/fetch',
        data: {
          'start_id': startFrom != null
              ? '${startFrom.millisecondsSinceEpoch}-0'
              : null,
          'limit': batchSize,
          'delete_policy': deleteOnMediator ? 'Optimistic' : 'DoNotDelete'
        },
        options: Options(headers: await getAuthorizationHeaders()),
      );

      return _responseToMessages(response);
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }

  /// Deletes messages from the mediator by message IDs.
  ///
  /// [messageIds] - The list of message IDs to fetch.
  ///
  /// Returns a list of messages.
  Future<void> deleteMessages({
    required List<String> messageIds,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/delete',
        data: {'message_ids': messageIds},
        options: Options(headers: await getAuthorizationHeaders()),
      );
      // TODO: return response to indicate which messages were deleted successfully
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }

  /// Listens for incoming messages from the mediator via WebSocket.
  ///
  /// [onMessage] - Callback for each received message.
  ///   **Important:**
  ///   Consider implementing rate limiting, message validation, or other mechanisms
  ///   in your callback to prevent potential denial-of-service (DDoS) attacks,
  ///   as this handler may be invoked for every message received from the network.
  /// [onError] - Optional callback for errors.
  /// [onDone] - Optional callback when the stream is closed.
  /// [cancelOnError] - Whether to cancel on error.
  ///
  /// Returns a [StreamSubscription] for the WebSocket stream.
  StreamSubscription listenForIncomingMessages(
    void Function(Map<String, dynamic>) onMessage, {
    Function? onError,
    void Function({int? closeCode, String? closeReason})? onDone,
    bool? cancelOnError,
  }) {
    return connectionPool.connect(
      mediatorClient: this,
      onMessage: onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Disconnects the WebSocket channel if connected.
  Future<void> disconnect() async {
    await connectionPool.disconnect(
      mediatorClient: this,
    );
  }

  /// Packs message, which then can be sent to mediator.
  Future<DidcommMessage> packMessage(
    PlainTextMessage message, {
    required MessageOptions messageOptions,
  }) async {
    DidcommMessage messageToSend = message;

    if (messageOptions.shouldSign) {
      messageToSend = await SignedMessage.pack(
        message,
        signer: signer,
      );
    }

    if (messageOptions.shouldEncrypt) {
      messageToSend = await EncryptedMessage.pack(
        messageToSend,
        keyPair: keyPair,
        didKeyId: didKeyId,
        keyType: keyPair.publicKey.type,
        recipientDidDocuments: [mediatorDidDocument],
        keyWrappingAlgorithm: messageOptions.keyWrappingAlgorithm,
        encryptionAlgorithm: messageOptions.encryptionAlgorithm,
      );
    }

    return messageToSend;
  }

  /// Returns authorization headers if an [authorizationProvider] is set, otherwise null.
  Future<Map<String, String>?> getAuthorizationHeaders() async {
    return authorizationProvider != null
        ? {
            'Authorization':
                'Bearer ${(await authorizationProvider!.getAuthorizationTokens()).accessToken}'
          }
        : null;
  }

  List<Map<String, dynamic>> _responseToMessages(
    Response<Map<String, dynamic>> response,
  ) {
    final data = response.data!['data'] as Map<String, dynamic>;

    return (data['success'] as List<dynamic>)
        .map(
          (item) => jsonDecode(
            (item as Map<String, dynamic>)['msg'] as String,
          ) as Map<String, dynamic>,
        )
        .toList();
  }
}
