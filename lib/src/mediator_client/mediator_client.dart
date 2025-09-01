import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../didcomm.dart';

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

  /// Options for forwarding messages to the mediator.
  final ForwardMessageOptions forwardMessageOptions;

  /// Options for WebSocket connections.
  final WebSocketOptions webSocketOptions;

  final Dio _dio;
  IOWebSocketChannel? _channel;

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
    this.forwardMessageOptions = const ForwardMessageOptions(),
    this.webSocketOptions = const WebSocketOptions(),
  }) : _dio = mediatorDidDocument.toDio(
          mediatorServiceType: DidDocumentServiceType.didCommMessaging,
        );

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
  /// [accessToken] - Optional bearer token for authentication.
  ///
  /// Returns the packed [DidcommMessage] that was sent.
  Future<DidcommMessage> sendMessage(
    ForwardMessage message, {
    String? accessToken,
  }) async {
    final messageToSend = await packMessage(
      message,
      messageOptions: forwardMessageOptions,
    );

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    try {
      await _dio.post<Map<String, dynamic>>(
        '/inbound',
        data: messageToSend,
        options: Options(headers: headers),
      );

      return messageToSend;
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }

  /// Lists message IDs in the inbox for the current actor.
  ///
  /// [accessToken] - Optional bearer token for authentication.
  ///
  /// Returns a list of message IDs as strings.
  Future<List<String>> listInboxMessageIds({
    String? accessToken,
  }) async {
    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    final did = getDidFromId(didKeyId);

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/list/${sha256.convert(utf8.encode(did)).toString()}/inbox',
        options: Options(headers: headers),
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

  /// Receives messages from the mediator by message IDs.
  ///
  /// [messageIds] - The list of message IDs to fetch.
  /// [deleteOnMediator] - Whether to delete messages from the mediator after fetching (default: true).
  /// [accessToken] - Optional bearer token for authentication.
  ///
  /// Returns a list of message.
  Future<List<Map<String, dynamic>>> receiveMessages({
    required List<String> messageIds,
    bool deleteOnMediator = true,
    String? accessToken,
  }) async {
    // TODO: create exception to wrap errors

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/outbound',
        data: {'message_ids': messageIds, 'delete': deleteOnMediator},
        options: Options(headers: headers),
      );

      final data = response.data!['data'] as Map<String, dynamic>;

      return (data['success'] as List<dynamic>)
          .map(
            (item) => jsonDecode(
              (item as Map<String, dynamic>)['msg'] as String,
            ) as Map<String, dynamic>,
          )
          .toList();
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }

  /// Listens for incoming messages from the mediator via WebSocket.
  ///
  /// [onMessage] - Callback for each received message.
  /// [onError] - Optional callback for errors.
  /// [onDone] - Optional callback when the stream is closed.
  /// [cancelOnError] - Whether to cancel on error.
  /// [accessToken] - Optional bearer token for authentication.
  ///
  /// Returns a [StreamSubscription] for the WebSocket stream.
  Future<StreamSubscription> listenForIncomingMessages(
    void Function(Map<String, dynamic>) onMessage, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
    String? accessToken,
  }) async {
    if (_channel != null) {
      await disconnect();
    }

    _channel = mediatorDidDocument.toWebSocketChannel(
      accessToken: accessToken,
      pingIntervalInSeconds: webSocketOptions.pingIntervalInSeconds,
    );

    await _channel!.ready;

    final subscription = _channel!.stream.listen(
      (data) => onMessage(
        jsonDecode(data as String) as Map<String, dynamic>,
      ),
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    final senderDid = getDidFromId(didKeyId);

    if (webSocketOptions.statusRequestMessageOptions.shouldSend) {
      final setupRequestMessage = StatusRequestMessage(
        id: const Uuid().v4(),
        to: [mediatorDidDocument.id],
        from: senderDid,
        recipientDid: senderDid,
      );

      _sendMessageToChannel(
        await packMessage(
          setupRequestMessage,
          messageOptions: webSocketOptions.statusRequestMessageOptions,
        ),
      );
    }

    if (webSocketOptions.liveDeliveryChangeMessageOptions.shouldSend) {
      final liveDeliveryChangeMessage = LiveDeliveryChangeMessage(
        id: const Uuid().v4(),
        to: [mediatorDidDocument.id],
        from: senderDid,
        liveDelivery: true,
      );

      _sendMessageToChannel(
        await packMessage(
          liveDeliveryChangeMessage,
          messageOptions: webSocketOptions.liveDeliveryChangeMessageOptions,
        ),
      );
    }

    return subscription;
  }

  /// Disconnects the WebSocket channel if connected.
  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close(status.normalClosure);
    }
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

  void _sendMessageToChannel(DidcommMessage message) {
    if (_channel == null) {
      throw Exception(
        'WebSockets connection has not configured yet. Call listenForIncomingMessages first.',
      );
    }

    _channel!.sink.add(
      jsonEncode(message),
    );
  }
}
