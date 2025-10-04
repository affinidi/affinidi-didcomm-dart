part of 'mediator_client.dart';

class ConnectionPool {
  final _connections = <String, Connection>{};

  static final ConnectionPool instance = ConnectionPool();
  final _lock = Lock();

  Future<StreamSubscription<dynamic>> start({
    required MediatorClient mediatorClient,
    required void Function(Map<String, dynamic>) onMessage,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) async {
    await _lock.synchronized(() async {
      if (!_connections.containsKey(mediatorClient.didKeyId)) {
        _connections[mediatorClient.didKeyId] =
            await Connection.init(mediatorClient: mediatorClient);
      }
    });

    final connection = _connections[mediatorClient.didKeyId]!;

    return connection.stream.listen(
      onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future<void> disconnect({
    required MediatorClient mediatorClient,
  }) async {
    final did = mediatorClient.didKeyId;
    final connection = _connections[did];

    if (connection != null) {
      _connections.remove(did);
      await connection.disconnect();
    }
  }
}
