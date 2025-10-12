part of 'mediator_client.dart';

/// Maintains a pool of [Connection]s shared across multiple [MediatorClient]s,
/// enabling concurrent WebSocket usage and reusing existing connections.

class ConnectionPool {
  /// The singleton instance of [ConnectionPool].
  static final ConnectionPool instance = ConnectionPool();

  final _connections = <String, Connection>{};
  final _subscriptions =
      <MediatorClient, StreamSubscription<Map<String, dynamic>>>{};

  /// Starts all connections in the pool.
  Future<void> startConnections() async {
    await Future.wait(
      _connections.values.map((connection) => connection.start()),
    );
  }

  /// Stops all connections and cancels all subscriptions in the pool.
  Future<void> stopConnections() async {
    await Future.wait(
      [
        ..._connections.values.map((connection) => connection.stop()),
        ..._subscriptions.values.map((subscription) => subscription.cancel()),
      ],
    );

    _subscriptions.clear();
    _connections.clear();
  }

  /// Connects to a [MediatorClient] and subscribes to its message stream.
  ///
  /// Throws a [StateError] if a subscription for the provided [mediatorClient] already exists.
  /// Throws an [UnsupportedError] if attempting to connect to a different mediator.
  ///
  /// Returns a [StreamSubscription] for the message stream.
  StreamSubscription connect({
    required MediatorClient mediatorClient,
    required void Function(Map<String, dynamic>) onMessage,
    Function? onError,
    void Function({int? closeCode, String? closeReason})? onDone,
    bool? cancelOnError,
  }) {
    if (_subscriptions.containsKey(mediatorClient)) {
      throw StateError(
        'A subscription for the provided MediatorClient already exists.',
      );
    }

    if (_subscriptions.isNotEmpty) {
      final commonMediatorDidDocument =
          _subscriptions.keys.first.mediatorDidDocument;

      if (commonMediatorDidDocument.id !=
          mediatorClient.mediatorDidDocument.id) {
        throw UnsupportedError(
          'Only one mediator can be used at this time',
        );
      }
    }

    if (!_connections.containsKey(mediatorClient.didKeyId)) {
      _connections[mediatorClient.didKeyId] = Connection(
        mediatorClient: mediatorClient,
      );
    }

    final connection = _connections[mediatorClient.didKeyId]!;

    final subscription = connection.stream.listen(
      onMessage,
      onError: onError,
      onDone: onDone != null
          ? () => onDone(
                closeCode: connection.channel?.closeCode,
                closeReason: connection.channel?.closeReason,
              )
          : null,
      cancelOnError: cancelOnError,
    );

    _subscriptions[mediatorClient] = subscription;
    return subscription;
  }

  /// Disconnects and cancels the subscription for the given [mediatorClient].
  Future<void> disconnect({
    required MediatorClient mediatorClient,
  }) async {
    await _subscriptions.remove(mediatorClient)?.cancel();
  }
}
