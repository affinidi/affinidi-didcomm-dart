import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../didcomm.dart';

/// Represents a root DIDComm ACL Management Message.
///
/// This message is used as a parent to all ACL Management messages.
abstract class AclManagementMessage extends PlainTextMessage {
  /// The URI representing the message type.
  /// This is used to identify the specific protocol message type within DIDComm.
  static final messageType = Uri.parse(
    'https://didcomm.org/mediator/1.0/acl-management',
  );

  /// Constructs [AclManagementMessage].
  /// [id]: Unique message identifier.
  /// [from]: Sender's DID.
  /// [to]: List of recipient DIDs.
  /// [body]: Message body.
  /// [expiresTime]: Message expiration time (optional).
  AclManagementMessage({
    required super.id,
    required super.from,
    required super.to,
    required super.body,
    super.createdTime,
    super.expiresTime,
    super.threadId,
    super.parentThreadId,
    super.acknowledged,
    super.pleaseAcknowledge,
    super.attachments,
  }) : super(
          type: messageType,
        );
}

/// Represents a root DIDComm ACL Management Message.
///
/// This message is used to add DIDs to the mediator's ACL of the did (from).
class AccessListAddMessage extends AclManagementMessage {
  /// Lists of DIDs which shall be added to ACL.
  final List<String> theirDids;

  /// Constructs [AccessListAddMessage].
  /// [id]: Unique message identifier.
  /// [from]: Sender's DID.
  /// [to]: List of recipient DIDs .
  /// [theirDids]: Lists of DIDs which shall be added to ACL.
  /// [expiresTime]: Message expiration time (optional).
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

  /// Creates a [AccessListAddMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the message.
  factory AccessListAddMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = AccessListAddMessage.fromJson(json);
    final accessList =
        plainTextMessage.body?['access_list_add'] as Map<String, dynamic>?;

    return AccessListAddMessage(
      id: plainTextMessage.id,
      from: plainTextMessage.from,
      to: plainTextMessage.to,
      theirDids: accessList?['hashes'] as List<String>,
    );
  }
}

// TODO: should be eventually moved to TDK
/// Extension for [MediatorClient] to support Affinidi-specific ACL management.
///
/// ACL management is not covered by the DIDComm standard.
/// This extension provides a method to configure ACLs with an Affinidi mediator.
extension AffinidiAclManagementExtension on MediatorClient {
  /// Sends a [AclManagementMessage] to the mediator.
  ///
  /// [message] - The message to send.
  ///
  /// Returns the packed [DidcommMessage] that was sent.
  Future<DidcommMessage> sendAclManagementMessage(
    AclManagementMessage message,
  ) async {
    final dio = mediatorDidDocument.toDio(
      mediatorServiceType: DidDocumentServiceType.didCommMessaging,
    );

    final messageToSend = await packMessage(
      message,
      messageOptions: forwardMessageOptions,
    );

    try {
      await dio.post<Map<String, dynamic>>(
        '/inbound',
        data: messageToSend,
        options: Options(headers: await getAuthorizationHeaders()),
      );

      return messageToSend;
    } on DioException catch (error) {
      throw MediatorClientException(innerException: error);
    }
  }
}
