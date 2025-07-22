import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../didcomm.dart';
import '../common/did_document_service_type.dart';
import '../mediator_client/mediator_client_exception.dart';

///
class AclManagementMessage extends PlainTextMessage {
  ///
  AclManagementMessage({
    required super.id,
    required super.from,
    required super.to,
    required super.body,
    super.expiresTime,
  }) : super(
          type: Uri.parse('https://didcomm.org/mediator/1.0/acl-management'),
        );
}

///
class AccessListAddMessage extends AclManagementMessage {
  final List<String> theirDids;

  ///
  AccessListAddMessage({
    required super.id,
    required super.from,
    required super.to,
    required this.theirDids,
    super.expiresTime,
  }) : super(
          body: {
            'access_list_add': {
              'did_hash': sha256.convert(utf8.encode(from!)).toString(),
              'hashes': theirDids
                  .map((did) => sha256.convert(utf8.encode(did)).toString())
                  .toList(),
            }
          },
        );

  factory AccessListAddMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = PlainTextMessage.fromJson(json);
    return AccessListAddMessage(
      id: plainTextMessage.id,
      from: plainTextMessage.from,
      to: plainTextMessage.to,
      theirDids:
          plainTextMessage.body?['access_list_add']?['hashes'] as List<String>,
    );
  }
}

// TODO: should be eventually moved to TDK
/// Extension for [MediatorClient] to support Affinidi-specific authentication.
///
/// Authentication by mediators is not covered by the DIDComm standard.
/// This extension provides a method to authenticate with an Affinidi mediator.
extension AffinidiAclManagementExtension on MediatorClient {
  /// Sends a [AclManagementMessage] to the mediator.
  ///
  /// [message] - The message to send.
  /// [accessToken] - Optional bearer token for authentication.
  ///
  /// Returns the packed [DidcommMessage] that was sent.
  Future<DidcommMessage> sendAclManagementMessage(
    AclManagementMessage message, {
    String? accessToken,
  }) async {
    final dio = mediatorDidDocument.toDio(
      mediatorServiceType: DidDocumentServiceType.didCommMessaging,
    );

    final messageToSend = await packMessage(
      message,
      messageOptions: forwardMessageOptions,
    );

    final headers =
        accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null;

    try {
      await dio.post<Map<String, dynamic>>(
        '/inbound',
        data: messageToSend,
        options: Options(headers: headers),
      );

      return messageToSend;
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }
}
