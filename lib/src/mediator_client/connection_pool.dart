part of 'mediator_client.dart';

class ConnectionPool {
  static final ConnectionPool instance = ConnectionPool();

  final _connections = <String, Connection>{};
  final _subscriptions =
      <MediatorClient, StreamSubscription<Map<String, dynamic>>>{};

  Future<void> startConnections() async {
    await Future.wait(
      _connections.values.map((connection) => connection.start()),
    );
  }

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

  StreamSubscription connect({
    required MediatorClient mediatorClient,
    required void Function(Map<String, dynamic>) onMessage,
    Function? onError,
    void Function()? onDone,
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
      _connections[mediatorClient.didKeyId] = Connection(mediatorClient);
    }

    final connection = _connections[mediatorClient.didKeyId]!;

    final subscription = connection.stream.listen(
      onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    _subscriptions[mediatorClient] = subscription;
    return subscription;
  }

  Future<void> disconnect({
    required MediatorClient mediatorClient,
  }) async {
    await _subscriptions.remove(mediatorClient)?.cancel();
  }
}
