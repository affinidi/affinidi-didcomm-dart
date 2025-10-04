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

  Connection(this.mediatorClient)
      : _controller = StreamController<Map<String, dynamic>>.broadcast();

  Future<void> start() async {
    _channel = mediatorClient.mediatorDidDocument.toWebSocketChannel(
      accessToken: await mediatorClient.authorizationProvider?.getAccessToken(),
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
      onDone: () {
        // TODO: closeCode and closeReason
        print(_channel!.closeCode);
        print(_channel!.closeReason);
        // controller.close();
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
  }

  void _sendMessage(DidcommMessage message) {
    if (_channel == null) {
      throw StateError('WebSocket channel is not initialized');
    }

    _channel!.sink.add(
      jsonEncode(message),
    );
  }

  Future<void> stop() async {
    await _channel?.sink.close(status.normalClosure);
    await _controller.close();
  }
}
