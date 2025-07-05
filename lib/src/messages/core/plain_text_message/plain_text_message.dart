import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../didcomm.dart';
import '../../../annotations/own_json_properties.dart';
import '../../../common/did.dart';
import '../../../converters/epoch_seconds_converter.dart';

part 'plain_text_message.g.dart';
part 'plain_text_message.own_json_props.g.dart';

/// Represents a DIDComm v2 Plain Text Message as defined in the DIDComm Messaging specification.
///
/// See: https://identity.foundation/didcomm-messaging/spec/#didcomm-plaintext-messages
@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PlainTextMessage extends DidcommMessage {
  /// Unique identifier for the message ("id" field in DIDComm spec).
  final String id;

  /// Message type URI.
  final Uri type;

  /// Sender's DID. Optional.
  final String? from;

  /// List of recipient DIDs. Optional.
  final List<String>? to;

  /// Thread ID for message threading ("thid" field in DIDComm spec). Optional.
  @JsonKey(name: 'thid')
  final String? threadId;

  /// Parent thread ID for nested threading ("pthid" field in DIDComm spec). Optional.
  @JsonKey(name: 'pthid')
  final String? parentThreadId;

  /// Message creation time as a UTC timestamp ("created_time" field in DIDComm spec). Optional.
  @JsonKey(name: 'created_time')
  @EpochSecondsConverter()
  final DateTime? createdTime;

  /// Message expiration time as a UTC timestamp ("expires_time" field in DIDComm spec). Optional.
  @JsonKey(name: 'expires_time')
  @EpochSecondsConverter()
  final DateTime? expiresTime;

  /// Massage IDs that need acknowledgment ("please_ack" field in DIDComm spec). Optional.
  /// The ID of the current message is always implicitly requested to be acknowledged if this field is present.
  /// The empty list means only the current message should be acknowledged.
  ///
  /// See: https://identity.foundation/didcomm-messaging/spec/#acks
  @JsonKey(name: 'please_ack')
  final List<String>? pleaseAcknowledge;

  /// List of message IDs that are being acknowledged by this message ("ack" field in DIDComm spec). Optional.
  ///
  /// See: https://identity.foundation/didcomm-messaging/spec/#acks
  @JsonKey(name: 'ack')
  final List<String>? acknowledged;

  /// Message body, containing protocol-specific content.
  final Map<String, dynamic>? body;

  /// List of attachments. Optional.
  final List<Attachment>? attachments;

  static const _unorderedEquality = UnorderedIterableEquality<String>();
  static const _jweHeaderConverter = JweHeaderConverter();

  /// Constructs a [PlainTextMessage].
  ///
  /// [id]: Unique message identifier.
  /// [type]: Message type URI.
  /// [from]: Sender's DID (optional).
  /// [to]: List of recipient DIDs (optional).
  /// [threadId]: Thread ID for message threading (optional).
  /// [parentThreadId]: Parent thread ID for nested threading (optional).
  /// [createdTime]: Message creation time (optional).
  /// [expiresTime]: Message expiration time (optional).
  /// [body]: Message body (optional).
  /// [attachments]: List of attachments (optional).
  PlainTextMessage({
    required this.id,
    required this.type,
    this.from,
    this.to,
    this.threadId,
    this.parentThreadId,
    this.createdTime,
    this.expiresTime,
    this.pleaseAcknowledge,
    this.acknowledged,
    this.body,
    this.attachments,
  });

  /// Creates a [PlainTextMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the message.
  factory PlainTextMessage.fromJson(Map<String, dynamic> json) {
    final message = _$PlainTextMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  /// Serializes the message to a JSON map, including custom headers.
  @override
  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$PlainTextMessageToJson(this));

  /// Validates addressing consistency between this PlainTextMessage and an [EncryptedMessage].
  ///
  /// Throws [ArgumentError] if the addressing is inconsistent.
  ///
  /// See: https://identity.foundation/didcomm-messaging/spec/#message-layer-addressing-consistency
  void validateConsistencyWithEncryptedMessage(EncryptedMessage message) {
    _validateFromHeader(
      encryptionKeyId:
          _jweHeaderConverter.fromJson(message.protected).subjectKeyId,
    );

    _validateToHeader(
      recipientsFromEncryptedMessage: message.recipients,
    );
  }

  /// Validates addressing consistency between this PlainTextMessage and a [SignedMessage].
  ///
  /// Throws [ArgumentError] if the addressing is inconsistent.
  ///
  /// See: https://identity.foundation/didcomm-messaging/spec/#message-layer-addressing-consistency
  void validateConsistencyWithSignedMessage(SignedMessage message) {
    _validateFromHeader(
      signatureKeyIds: message.signatures
          .map(
            (signature) => signature.header.keyId,
          )
          .toList(),
    );
  }

  void _validateToHeader({
    List<Recipient>? recipientsFromEncryptedMessage,
  }) {
    final recipientKeyIds = recipientsFromEncryptedMessage?.map(
      (recipient) => getDidFromId(recipient.header.keyId),
    );

    if (recipientKeyIds != null) {
      if (to == null) {
        throw ArgumentError(
          'to header is required if a Plain Text Message is inside of Encrypted Message',
          'message',
        );
      }

      final areEqual = _unorderedEquality.equals(
        recipientKeyIds,
        to,
      );

      if (!areEqual) {
        throw ArgumentError(
          'Recipients in an Encrypted Message do not match recipients IDs in a Plain Text Message',
          'message',
        );
      }
    }
  }

  void _validateFromHeader({
    String? encryptionKeyId,
    List<String>? signatureKeyIds,
  }) {
    final senderDid =
        encryptionKeyId == null ? null : getDidFromId(encryptionKeyId);

    final signerDids = signatureKeyIds?.map(
      getDidFromId,
    );

    if (signerDids != null && !signerDids.contains(from)) {
      throw ArgumentError(
        'from header in a Plain Text Message can not be found in signatures of a Signed Message'
        'message',
      );
    }

    if (senderDid != null && from != senderDid) {
      throw ArgumentError(
        'from header in a Plain Text Message does not match skid header in an Encrypted Message',
        'message',
      );
    }
  }
}
