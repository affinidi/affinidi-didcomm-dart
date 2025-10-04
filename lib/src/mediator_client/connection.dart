import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../didcomm.dart';
import '../common/crypto.dart';

class Connection {
  final MediatorClient mediatorClient;
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  final StreamController<Map<String, dynamic>> _controller;
  IOWebSocketChannel? _channel;
  AuthorizationTokens? _authorizationTokens;

  Connection(this.mediatorClient)
      : _controller = StreamController<Map<String, dynamic>>.broadcast();

  Future<void> start() async {
    _authorizationTokens =
        await mediatorClient.authorizationProvider?.getAuthorizationTokens();

    _channel = mediatorClient.mediatorDidDocument.toWebSocketChannel(
      accessToken: _authorizationTokens?.accessToken,
      webSocketOptions: mediatorClient.webSocketOptions,
    );

    await _channel!.ready;

    _channel!.stream.listen(
      (data) async {
        final json = data as String;

        final messageIdOnMediator = hex.encode(
          sha256Hash(
            utf8.encode(json),
          ),
        );

        await mediatorClient.deleteMessages(
          messageIds: [messageIdOnMediator],
        );

        _controller.add(
          jsonDecode(json) as Map<String, dynamic>,
        );
      },
      onError: _controller.addError,
      onDone: () async {
        // check if the connection was closed due to token expiration
        if (_authorizationTokens?.accessExpiresAt
                .isBefore(DateTime.now().toUtc()) ==
            true) {
          await start();
        }
        // TODO: handle other disconnection reasons and implement reconnection logic if needed
        else {
          await stop();
        }
      },
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
      );
    }

    // fetch messages that were sent before the WebSocket connection was established
    unawaited(
      mediatorClient.fetchMessagesStartingFrom().then((messages) {
        for (final message in messages) {
          _controller.add(message);
        }
      }),
    );
  }

  Future<void> stop() async {
    _authorizationTokens = null;

    await _channel?.sink.close(status.normalClosure);
    await _controller.close();
  }

  void _sendMessage(DidcommMessage message) {
    if (_channel == null) {
      throw StateError('WebSocket channel is not initialized');
    }

    _channel!.sink.add(
      jsonEncode(message),
    );
  }
}
