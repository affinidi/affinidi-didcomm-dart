import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../didcomm.dart';
import '../common/did_document_service_type.dart';
import '../extensions/extensions.dart';

class MediatorClient {
  final DidDocument mediatorDidDocument;
  final KeyPair keyPair;
  final String didKeyId;
  final DidSigner signer;
  final ForwardMessageOptions forwardMessageOptions;
  final WebSocketOptions webSocketOptions;

  final Dio _dio;
  late final IOWebSocketChannel? _channel;

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

  static Future<MediatorClient> fromMediatorDidDocumentUri(
    Uri didDocumentUrl, {
    required KeyPair keyPair,
    required String didKeyId,
    required DidSigner signer,
  }) async {
    return MediatorClient(
      mediatorDidDocument: await UniversalDIDResolver.resolve(
        didDocumentUrl.toString(),
      ),
      keyPair: keyPair,
      didKeyId: didKeyId,
      signer: signer,
    );
  }

  // TODO: create exception to wrap errors
  Future<DidcommMessage> sendMessage(
    ForwardMessage message, {
    String? accessToken,
  }) async {
    DidcommMessage messageToSend = await _packMessage(
      message,
      messageOptions: forwardMessageOptions,
    );

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    await _dio.post<Map<String, dynamic>>(
      '/inbound',
      data: messageToSend,
      options: Options(headers: headers),
    );

    return messageToSend;
  }

  // TODO: create exception to wrap errors
  Future<List<String>> listInboxMessageIds({
    String? accessToken,
  }) async {
    final actorDidDocument = await _getActorDidDocument();

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    final response = await _dio.get<Map<String, dynamic>>(
      '/list/${sha256.convert(utf8.encode(actorDidDocument.id)).toString()}/inbox',
      options: Options(headers: headers),
    );

    return (response.data!['data'] as List<dynamic>)
        .map(
          (item) => (item as Map<String, dynamic>)['msg_id'] as String,
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> receiveMessages({
    required List<String> messageIds,
    bool deleteOnMediator = true,
    String? accessToken,
  }) async {
    // TODO: create exception to wrap errors

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

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
  }

  Future<StreamSubscription> listenForIncomingMessages(
    void Function(Map<String, dynamic>) onMessage, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
    String? accessToken,
  }) async {
    _channel = mediatorDidDocument.toWebSocketChannel(
      accessToken: accessToken,
    );

    await _channel!.ready;

    final subscription = _channel.stream.listen(
      (data) => onMessage(
        jsonDecode(data as String) as Map<String, dynamic>,
      ),
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    final actorDidDocument = await _getActorDidDocument();

    if (webSocketOptions.statusRequestMessageOptions.shouldSend) {
      final setupRequestMessage = StatusRequestMessage(
        id: const Uuid().v4(),
        to: [mediatorDidDocument.id],
        from: actorDidDocument.id,
        recipientDid: actorDidDocument.id,
      );

      _sendMessageToChannel(
        await _packMessage(
          setupRequestMessage,
          messageOptions: webSocketOptions.statusRequestMessageOptions,
        ),
      );
    }

    if (webSocketOptions.liveDeliveryChangeMessageOptions.shouldSend) {
      final liveDeliveryChangeMessage = LiveDeliveryChangeMessage(
        id: const Uuid().v4(),
        to: [mediatorDidDocument.id],
        from: actorDidDocument.id,
        liveDelivery: true,
      );

      _sendMessageToChannel(
        await _packMessage(
          liveDeliveryChangeMessage,
          messageOptions: webSocketOptions.liveDeliveryChangeMessageOptions,
        ),
      );
    }

    return subscription;
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel.sink.close(status.normalClosure);
    }
  }

  Future<DidDocument> _getActorDidDocument() async {
    return DidKey.generateDocument(
      keyPair.publicKey,
    );
  }

  Future<DidcommMessage> _packMessage(
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

    _channel.sink.add(
      jsonEncode(message),
    );
  }
}
