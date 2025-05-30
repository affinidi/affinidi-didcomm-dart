import 'dart:async';
import 'dart:convert';

import 'package:didcomm/src/messages/core/encrypted_message/encrypted_message.dart';
import 'package:didcomm/src/messages/core/plain_text_message/plain_text_message.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../extensions/extensions.dart';
import '../jwks/jwks.dart';
import '../messages/algorithm_types/encryption_algorithm.dart';
import '../messages/didcomm_message.dart';
import 'mediator_service_type.dart';

class MediatorClient {
  final DidDocument mediatorDidDocument;
  final Dio _dio;

  late final IOWebSocketChannel? _channel;

  MediatorClient({
    required this.mediatorDidDocument,
  }) : _dio = mediatorDidDocument.toDio(
          mediatorServiceType: MediatorServiceType.didCommMessaging,
        );

  static Future<MediatorClient> fromDidDocumentUri(Uri didDocumentUrl) async {
    final response = await Dio().getUri(didDocumentUrl);

    return MediatorClient(
      mediatorDidDocument: DidDocument.fromJson(response.data),
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
    void Function(Map<String, dynamic>) onMessage, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
    String? accessToken,
    required Wallet recipientWallet,
    required String recipientKeyId,
  }) async {
    final recipientKeyPair = await recipientWallet.getKeyPair(recipientKeyId);
    final recipientDidDocument = DidKey.generateDocument(
      recipientKeyPair.publicKey,
    );

    _channel = mediatorDidDocument.toWebSocketChannel(
      accessToken: accessToken,
    );

    await _channel!.ready;

    final subscription = _channel.stream.listen(
      (data) => onMessage(jsonDecode(data)),
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    final setupMessage = PlainTextMessage(
      id: Uuid().v4(),
      type: Uri.parse('https://didcomm.org/messagepickup/3.0/status-request'),
      // body: {'recipient_did': sdk.alias.did},
      to: [mediatorDidDocument.id],
      from: recipientDidDocument.id,
    );

    final mediatorJwks = mediatorDidDocument.keyAgreement.map((keyAgreement) {
      final jwk = keyAgreement.asJwk().toJson();
      // TODO: kid is not available in the Jwk anymore. clarify with the team
      jwk['kid'] = keyAgreement.id;

      return jwk;
    }).toList();

    final encryptedSetupMessage = await EncryptedMessage.packWithAuthentication(
      setupMessage,
      wallet: recipientWallet,
      keyId: recipientKeyId,
      jwksPerRecipient: [
        Jwks.fromJson({
          'keys': mediatorJwks,
        }),
      ],
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    );

    _channel.sink.add(
      jsonEncode(encryptedSetupMessage),
    );

    return subscription;
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel.sink.close(status.normalClosure);
    }
  }
}
