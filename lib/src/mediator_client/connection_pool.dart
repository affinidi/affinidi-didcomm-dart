part of 'mediator_client.dart';

class ConnectionPool {
  final _connections = <String, IOWebSocketChannel>{};

  static final ConnectionPool instance = ConnectionPool();

  Future<StreamSubscription<dynamic>> start({
    required MediatorClient mediatorClient,
    required void Function(Map<String, dynamic>) onMessage,
    Function? onError,
    void Function({int? closeCode, String? closeReason})? onDone,
    bool? cancelOnError,
  }) async {
    await disconnect(mediatorClient: mediatorClient);

    final channel = mediatorClient.mediatorDidDocument.toWebSocketChannel(
      accessToken: await mediatorClient.authorizationProvider?.getAccessToken(),
      webSocketOptions: mediatorClient.webSocketOptions,
    );

    _connections[mediatorClient.didKeyId] = channel;
    await channel.ready;

    final subscription = channel.stream.listen(
      (data) async {
        final json = data as String;

        // TODO: come back to this after the mediator will bypass message queue on Live Delivery
        if (mediatorClient.webSocketOptions.deleteOnMediator) {
          final messageIdOnMediator = hex.encode(sha256Hash(utf8.encode(json)));
          await mediatorClient.deleteMessages(
            messageIds: [messageIdOnMediator],
          );
        }
        onMessage(
          jsonDecode(json) as Map<String, dynamic>,
        );
      },
      onError: onError,
      onDone: () => onDone != null
          ? onDone(
              closeCode: channel.closeCode,
              closeReason: channel.closeReason,
            )
          : null,
      cancelOnError: cancelOnError,
    );

    final senderDid = getDidFromId(mediatorClient.didKeyId);

    if (mediatorClient
        .webSocketOptions.statusRequestMessageOptions.shouldSend) {
      final setupRequestMessage = StatusRequestMessage(
        id: const Uuid().v4(),
        to: [mediatorClient.mediatorDidDocument.id],
        from: senderDid,
        recipientDid: senderDid,
      );

      _sendMessage(
        await mediatorClient.packMessage(
          setupRequestMessage,
          messageOptions:
              mediatorClient.webSocketOptions.statusRequestMessageOptions,
        ),
        channel: channel,
      );
    }

    if (mediatorClient
        .webSocketOptions.liveDeliveryChangeMessageOptions.shouldSend) {
      final liveDeliveryChangeMessage = LiveDeliveryChangeMessage(
        id: const Uuid().v4(),
        to: [mediatorClient.mediatorDidDocument.id],
        from: senderDid,
        liveDelivery: true,
      );

      _sendMessage(
        await mediatorClient.packMessage(
          liveDeliveryChangeMessage,
          messageOptions:
              mediatorClient.webSocketOptions.liveDeliveryChangeMessageOptions,
        ),
        channel: channel,
      );
    }

    return subscription;
  }

  Future<void> disconnect({
    required MediatorClient mediatorClient,
  }) async {
    final did = mediatorClient.didKeyId;

    if (_connections.containsKey(did)) {
      await _connections[did]!.sink.close(status.normalClosure);
    }
  }

  void _sendMessage(
    DidcommMessage message, {
    required IOWebSocketChannel channel,
  }) {
    channel.sink.add(
      jsonEncode(message),
    );
  }
}
