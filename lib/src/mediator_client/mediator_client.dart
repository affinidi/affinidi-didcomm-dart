import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:didcomm/didcomm.dart';
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
  final Wallet _wallet;
  final String _keyId;
  final DidSigner _didSigner;

  late final IOWebSocketChannel? _channel;

  MediatorClient({
    required this.mediatorDidDocument,
    required Wallet wallet,
    required String keyId,
    required DidSigner didSigner,
  })  : _dio = mediatorDidDocument.toDio(
          mediatorServiceType: MediatorServiceType.didCommMessaging,
        ),
        _wallet = wallet,
        _keyId = keyId,
        _didSigner = didSigner;

  static Future<MediatorClient> fromMediatorDidDocumentUri(
    Uri didDocumentUrl, {
    required Wallet wallet,
    required String keyId,
    required DidSigner didSigner,
  }) async {
    final response = await Dio().getUri(didDocumentUrl);

    return MediatorClient(
      mediatorDidDocument: DidDocument.fromJson(response.data),
      wallet: wallet,
      keyId: keyId,
      didSigner: didSigner,
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

  Future<List<String>> listInboxMessageIds({
    String? accessToken,
  }) async {
    // TODO: create exception to wrap errors

    final actorDidDocument = await _getActorDidDocument();

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    final response = await _dio.get(
      '/list/${sha256.convert(utf8.encode(actorDidDocument.id)).toString()}/inbox',
      options: Options(headers: headers),
    );

    return (response.data['data'] as List<dynamic>)
        .map(
          (item) => item['msg_id'] as String,
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> receiveMessages({
    required List<String> messageIds,
    bool deleteOnMediator = true,
    String? accessToken,
  }) async {
    // TODO: create exception to wrap errors

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    final response = await _dio.post(
      '/outbound',
      data: {'message_ids': messageIds, 'delete': deleteOnMediator},
      options: Options(headers: headers),
    );

    return (response.data['data']['success'] as List<dynamic>)
        .map(
          (item) => jsonDecode(item['msg'] as String) as Map<String, dynamic>,
        )
        .toList();
  }

  Future<StreamSubscription> listenForIncomingMessages(
    void Function(Map<String, dynamic>) onMessage, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
    String? accessToken,
  }) async {
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

    final actorDidDocument = await _getActorDidDocument();

    // TODO: create a class StatusRuest and place it to lib/src/messages/protocols
    final setupMessage = PlainTextMessage(
      id: Uuid().v4(),
      type: Uri.parse('https://didcomm.org/messagepickup/3.0/status-request'),
      body: {'recipient_did': actorDidDocument.id},
      to: [mediatorDidDocument.id],
      from: actorDidDocument.id,
    );

    setupMessage['return_route'] = 'all';

    //     DidcommEncryptedMessage liveDelivery = await DidcommHelpers.pack(
    //   sdk.wallet,
    //   DidcommMessageTypes.LiveDeliveryChange,
    //   {'live_delivery': true},
    //   [sdk.mediator.value.did],
    //   sdk.alias.did,
    //   sdk.mediator.value.keyAgreements,
    //   returnRoute: ReturnRouteValue.all,
    // );

    final mediatorJwks = mediatorDidDocument.keyAgreement.map((keyAgreement) {
      final jwk = keyAgreement.asJwk().toJson();
      // TODO: kid is not available in the Jwk anymore. clarify with the team
      jwk['kid'] = keyAgreement.id;

      return jwk;
    }).toList();

    final signedSetupMessage = await SignedMessage.pack(
      setupMessage,
      signer: _didSigner,
    );

    final encryptedSetupMessage = await EncryptedMessage.packWithAuthentication(
      signedSetupMessage,
      wallet: _wallet,
      keyId: _keyId,
      jwksPerRecipient: [
        Jwks.fromJson({
          'keys': mediatorJwks,
        }),
      ],
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    );

    final liveDeliveryMessage = PlainTextMessage(
      id: Uuid().v4(),
      type: Uri.parse(
          'https://didcomm.org/messagepickup/3.0/live-delivery-change'),
      body: {'live_delivery': true},
      to: [mediatorDidDocument.id],
      from: actorDidDocument.id,
    );

    liveDeliveryMessage['return_route'] = 'all';

    final liveDeliverySignedMessage = await SignedMessage.pack(
      liveDeliveryMessage,
      signer: _didSigner,
    );

    final liveDeliveryEncryptedMessage =
        await EncryptedMessage.packWithAuthentication(
      liveDeliverySignedMessage,
      wallet: _wallet,
      keyId: _keyId,
      jwksPerRecipient: [
        Jwks.fromJson({
          'keys': mediatorJwks,
        }),
      ],
      encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
    );

    _channel.sink.add(
      jsonEncode(liveDeliveryEncryptedMessage),
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

  Future<DidDocument> _getActorDidDocument() async {
    final recipientKeyPair = await _wallet.generateKey(keyId: _keyId);

    return DidKey.generateDocument(
      recipientKeyPair.publicKey,
    );
  }
}
