import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../didcomm.dart';
import '../common/crypto.dart';

class Connection {
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  final IOWebSocketChannel _channel;
  final StreamController<Map<String, dynamic>> _controller;

  Connection({
    required IOWebSocketChannel channel,
    required StreamController<Map<String, dynamic>> controller,
  })  : _channel = channel,
        _controller = controller;

  static Future<Connection> init({
    required MediatorClient mediatorClient,
  }) async {
    final channel = mediatorClient.mediatorDidDocument.toWebSocketChannel(
      accessToken: await mediatorClient.authorizationProvider?.getAccessToken(),
      webSocketOptions: mediatorClient.webSocketOptions,
    );

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    await channel.ready;

    channel.stream.listen(
      (data) async {
        final json = data as String;

        final messageIdOnMediator = hex.encode(sha256Hash(utf8.encode(json)));
        await mediatorClient.deleteMessages(
          messageIds: [messageIdOnMediator],
        );

        controller.add(
          jsonDecode(json) as Map<String, dynamic>,
        );
      },
      onError: controller.addError,
      onDone: () {
        print(channel.closeCode);
        print(channel.closeReason);
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

    // TODO: closeCode and closeReason

    return Connection(
      channel: channel,
      controller: controller,
    );
  }

  static void _sendMessage(
    DidcommMessage message, {
    required IOWebSocketChannel channel,
  }) {
    channel.sink.add(
      jsonEncode(message),
    );
  }

  Future<void> disconnect() async {
    await _channel.sink.close(status.normalClosure);
    await _controller.close();
  }
}
