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

  /// Inbox message ids that have already been emitted while the post-connect
  /// inbox drain is running.
  ///
  /// Shared between the WebSocket live-delivery path and [drainInboxMessages]
  /// so that a message delivered over the socket and also still present in the
  /// inbox (e.g. when `deleteOnReceive` is false) is emitted only once. It is
  /// only populated while [_isDrainingInbox] is true and cleared once draining
  /// finishes, so it does not grow for the lifetime of the connection.
  final _seenMessageIds = <String>{};

  /// Whether the post-connect inbox drain is currently running.
  ///
  /// Deduplication between live delivery and the inbox drain is only needed
  /// while the drain is active, since afterwards live delivery is the only
  /// source of messages.
  bool _isDrainingInbox = false;

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
            final messageIdOnMediator = hex.encode(
              sha256Hash(
                utf8.encode(json),
              ),
            );

            if (_mediatorClient.webSocketOptions.deleteOnReceive) {
              unawaited(_mediatorClient.deleteMessages(
                messageIds: [messageIdOnMediator],
              ).catchError(_controller.addError));
            }

            // A message may be delivered both over the WebSocket (live
            // delivery) and fetched from the inbox by [drainInboxMessages]
            // while the post-connect inbox drain is running (e.g. when
            // deleteOnReceive is false and the message is not removed from the
            // inbox). Deduplicate by the inbox message id only during that
            // window; once the drain has finished, live delivery is the only
            // source, so we stop tracking ids to avoid unbounded memory growth.
            if (_isDrainingInbox && !_seenMessageIds.add(messageIdOnMediator)) {
              return;
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
        // Messages forwarded to the inbox around the time the WebSocket
        // connection is being established may not be pushed over the socket
        // via live delivery, so they would otherwise stay in the inbox until
        // the next (re)connect. To cover that window we poll the inbox a few
        // times right after connecting and push any queued messages into the
        // stream.
        // TODO: the proper solution would be to wait for the live delivery
        // status message from the mediator and only then fetch all messages.
        // However, this requires significant refactoring since the DidManager,
        // needed to unpack the status message, is not available at the
        // connection level.

        // Deduplicate live-delivered messages against the drained ones only
        // while the drain is running (see the WebSocket listener above). The
        // flag is reset and the tracked ids are cleared once draining finishes
        // to avoid unbounded memory growth.
        _isDrainingInbox = true;

        unawaited(drainInboxMessages(
          listMessageIds: _mediatorClient.listInboxMessageIds,
          fetchMessagesByIds: (ids) => _mediatorClient.fetchMessagesByIds(
            ids,
            deleteOnMediator: _mediatorClient.webSocketOptions.deleteOnReceive,
          ),
          emit: (message) => _lock.synchronized(() async {
            if (channel == null) {
              // connection has been stopped
              return;
            }

            _controller.add(message);
          }),
          isActive: () => channel != null,
          seenMessageIds: _seenMessageIds,
        ).whenComplete(() {
          _isDrainingInbox = false;
          _seenMessageIds.clear();
        }));
      }
    });
  }

  /// Polls the mediator inbox up to [maxAttempts] times, [interval] apart, and
  /// emits any not-yet-seen messages via [emit].
  ///
  /// Messages are deduplicated by their inbox message id using [seenMessageIds]
  /// (which is mutated as ids are emitted), so a message that is still returned
  /// by a later poll (e.g. when messages are not deleted on the mediator) is
  /// emitted only once. The same set can be shared with another source (such as
  /// the WebSocket live-delivery path) so a message delivered there is not
  /// emitted again here. Polling stops early once [isActive] returns false.
  static Future<void> drainInboxMessages({
    required Future<List<String>> Function() listMessageIds,
    required Future<List<Map<String, dynamic>>> Function(List<String> ids)
        fetchMessagesByIds,
    required Future<void> Function(Map<String, dynamic> message) emit,
    required bool Function() isActive,
    required Set<String> seenMessageIds,
    int maxAttempts = 5,
    Duration interval = const Duration(seconds: 1),
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      // stop polling once the connection has been stopped
      if (!isActive()) {
        break;
      }

      final messageIds = await listMessageIds();
      final newMessageIds = messageIds.where(seenMessageIds.add).toList();

      if (newMessageIds.isNotEmpty) {
        final messages = await fetchMessagesByIds(newMessageIds);

        for (final message in messages) {
          await emit(message);
        }
      }

      await Future<void>.delayed(interval);
    }
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
