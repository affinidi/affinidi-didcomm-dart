import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../extensions/extensions.dart';
import '../messages/didcomm_message.dart';
import 'mediator_service_type.dart';

class MediatorClient {
  final DidDocument didDocument;
  final Dio _dio;

  late final IOWebSocketChannel? _channel;

  MediatorClient({
    required this.didDocument,
  }) : _dio = didDocument.toDio(
          mediatorServiceType: MediatorServiceType.didCommMessaging,
        );

  static Future<MediatorClient> fromDidDocumentUri(Uri didDocumentUrl) async {
    final response = await Dio().getUri(didDocumentUrl);

    return MediatorClient(
      didDocument: DidDocument.fromJson(response.data),
    );
  }

  Future<void> sendMessage(
    DidcommMessage message, {
    String? accessToken,
  }) async {
    // TODO: create exception to wrap errors

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    await _dio.post(
      '/inbound',
      data: message,
      options: Options(headers: headers),
    );
  }

  Future<StreamSubscription> listenForIncomingMessages(
    void Function(dynamic)? onMessage, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
    String? accessToken,
  }) async {
    _channel = didDocument.toWebSocketChannel(
      accessToken: accessToken,
    );

    await _channel!.ready;

    return _channel.stream.listen(
      onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel.sink.close(status.normalClosure);
    }
  }
}
