import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../didcomm.dart';
import '../common/crypto.dart';

/// Callback invoked when the connection is attempting to reconnect.
///
/// Provides optional [closeCode] and [closeReason] for the previous disconnect.
typedef OnReconnectingCallback = void Function({
  int? closeCode,
  String? closeReason,
});

/// Callback invoked when the connection has successfully reconnected.
typedef OnReconnectedCallback = void Function();

/// Manages a WebSocket connection to a DIDComm mediator, providing a stream of incoming messages.
class Connection {
  /// A broadcast stream of incoming messages from the mediator.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// The underlying WebSocket channel for this connection.
  ///
  /// This is initialized in [start] and is null before the connection is started.
  ///
  /// The channel instance is replaced each time the connection is (re)established,
  /// such as when reconnecting after a disconnect or token refresh.
  IOWebSocketChannel? channel;

  /// Callback invoked when the connection is attempting to reconnect.
  final OnReconnectingCallback? onReconnecting;

  /// Callback invoked when the connection has successfully reconnected.
  final OnReconnectedCallback? onReconnected;

  // TODO: create internal mediator client instead of passing it from outside
  final MediatorClient _mediatorClient;
  final StreamController<Map<String, dynamic>> _controller;

  AuthorizationTokens? _authorizationTokens;
  final _lock = Lock();

  /// Creates a [Connection] for the given [mediatorClient].
  Connection({
    required MediatorClient mediatorClient,
    this.onReconnecting,
    this.onReconnected,
  })  : _mediatorClient = mediatorClient,
        _controller = StreamController<Map<String, dynamic>>.broadcast();

  /// Starts the WebSocket connection and begins listening for messages.
  ///
  /// Automatically handles token refresh and message queue draining.
  Future<void> start() async {
    // prevent channel from being started multiple times concurrently
    await _lock.synchronized(() async {
      if (channel != null && channel!.closeCode == null) {
        // already started
        return;
      }

      _authorizationTokens =
          await _mediatorClient.authorizationProvider?.getAuthorizationTokens();

      channel = _mediatorClient.mediatorDidDocument.toWebSocketChannel(
        accessToken: _authorizationTokens?.accessToken,
        webSocketOptions: _mediatorClient.webSocketOptions,
      );

      await channel!.ready.catchError((Object err) {
        channel = null;
        throw err as Exception;
      });

      channel!.stream.listen(
        (data) async {
          // prevent connection from being closed while processing messages
          await _lock.synchronized(() async {
            final json = data as String;

            if (_mediatorClient.webSocketOptions.deleteOnReceive) {
              final messageIdOnMediator = hex.encode(
                sha256Hash(
                  utf8.encode(json),
                ),
              );
              unawaited(_mediatorClient.deleteMessages(
                messageIds: [messageIdOnMediator],
              ).catchError(_controller.addError));
            }

            _controller.add(
              jsonDecode(json) as Map<String, dynamic>,
            );
          });
        },
        onError: _controller.addError,
        onDone: () async {
          var shouldReconnect = false;

          await _lock.synchronized(() async {
            shouldReconnect =
                channel != null && channel!.closeCode != status.normalClosure;
          });

          if (shouldReconnect) {
            if (onReconnecting != null) {
              onReconnecting!(
                closeCode: channel?.closeCode,
                closeReason: channel?.closeReason,
              );
            }

            await _reconnect();

            if (onReconnected != null) {
              onReconnected!();
            }
          } else {
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
            messageOptions: _mediatorClient
                .webSocketOptions.liveDeliveryChangeMessageOptions,
          ),
        );
      }

      if (_mediatorClient.webSocketOptions.fetchMessagesOnConnect) {
        // fetch messages that were sent before the WebSocket connection was established
        unawaited(
          _mediatorClient
              .fetchMessages(
                  deleteOnMediator:
                      _mediatorClient.webSocketOptions.deleteOnReceive)
              .then((messages) async {
            for (final message in messages) {
              // prevent connection from being closed while processing messages
              await _lock.synchronized(() async {
                _controller.add(message);
              });
            }
          }),
        );
      }
    });
  }

  /// Stops the WebSocket connection and closes the message stream.
  Future<void> stop() async {
    // ensure we stop only if there are not messages being processed

    await _lock.synchronized(() async {
      if (channel == null) {
        // already stopped
        return;
      }

      _authorizationTokens = null;

      await channel?.sink.close(status.normalClosure);
      await _controller.close();

      channel = null;
    });
  }

  void _sendMessage(DidcommMessage message) {
    if (channel == null) {
      throw StateError('WebSocket channel is not initialized');
    }

    channel!.sink.add(
      jsonEncode(message),
    );
  }

  Future<void> _reconnect() async {
    while (true) {
      try {
        await start();
        return;
      } on WebSocketChannelException catch (e) {
        if (e.inner is SocketException) {
          await Future<void>.delayed(Duration(
            seconds: _mediatorClient.webSocketOptions.pingIntervalInSeconds,
          ));
          continue;
        }

        rethrow;
      } catch (e) {
        await stop();
        rethrow;
      }
    }
  }
}
