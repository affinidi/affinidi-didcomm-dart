import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../didcomm.dart';
import '../common/crypto.dart';

/// Manages a WebSocket connection to a DIDComm mediator, providing a stream of incoming messages.
class Connection {
  /// A broadcast stream of incoming messages from the mediator.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  // TODO: create internal mediator client instead of passing it from outside
  final MediatorClient _mediatorClient;
  final StreamController<Map<String, dynamic>> _controller;

  IOWebSocketChannel? _channel;
  AuthorizationTokens? _authorizationTokens;

  /// Creates a [Connection] for the given [mediatorClient].
  Connection({
    required MediatorClient mediatorClient,
  })  : _mediatorClient = mediatorClient,
        _controller = StreamController<Map<String, dynamic>>.broadcast();

  /// Starts the WebSocket connection and begins listening for messages.
  ///
  /// Automatically handles token refresh and message queue draining.
  Future<void> start() async {
    _authorizationTokens =
        await _mediatorClient.authorizationProvider?.getAuthorizationTokens();

    _channel = _mediatorClient.mediatorDidDocument.toWebSocketChannel(
      accessToken: _authorizationTokens?.accessToken,
      webSocketOptions: _mediatorClient.webSocketOptions,
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

        await _mediatorClient.deleteMessages(
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

    final senderDid = getDidFromId(_mediatorClient.didKeyId);

    if (_mediatorClient
        .webSocketOptions.statusRequestMessageOptions.shouldSend) {
      final setupRequestMessage = StatusRequestMessage(
        id: const Uuid().v4(),
        to: [_mediatorClient.mediatorDidDocument.id],
        from: senderDid,
        recipientDid: senderDid,
      );

      _sendMessage(
        await _mediatorClient.packMessage(
          setupRequestMessage,
          messageOptions:
              _mediatorClient.webSocketOptions.statusRequestMessageOptions,
        ),
      );
    }

    if (_mediatorClient
        .webSocketOptions.liveDeliveryChangeMessageOptions.shouldSend) {
      final liveDeliveryChangeMessage = LiveDeliveryChangeMessage(
        id: const Uuid().v4(),
        to: [_mediatorClient.mediatorDidDocument.id],
        from: senderDid,
        liveDelivery: true,
      );

      _sendMessage(
        await _mediatorClient.packMessage(
          liveDeliveryChangeMessage,
          messageOptions:
              _mediatorClient.webSocketOptions.liveDeliveryChangeMessageOptions,
        ),
      );
    }

    // fetch messages that were sent before the WebSocket connection was established
    unawaited(
      _mediatorClient.fetchMessages().then((messages) {
        for (final message in messages) {
          _controller.add(message);
        }
      }),
    );
  }

  /// Stops the WebSocket connection and closes the message stream.
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
