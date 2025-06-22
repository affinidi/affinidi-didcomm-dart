import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../didcomm.dart';
import '../../../annotations/own_json_properties.dart';
import '../../../common/did.dart';
import '../../../converters/epoch_seconds_converter.dart';

part 'plain_text_message.g.dart';
part 'plain_text_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PlainTextMessage extends DidcommMessage {
  static final _unorderedEquality = const UnorderedIterableEquality();

  final String id;
  final Uri type;
  final String? from;
  final List<String>? to;

  @JsonKey(name: 'thid')
  final String? threadId;

  @JsonKey(name: 'pthid')
  final String? parentThreadId;

  @JsonKey(name: 'created_time')
  @EpochSecondsConverter()
  final DateTime? createdTime;

  @JsonKey(name: 'expires_time')
  @EpochSecondsConverter()
  final DateTime? expiresTime;

  final Map<String, dynamic>? body;
  final List<Attachment>? attachments;

  PlainTextMessage({
    required this.id,
    required this.type,
    this.from,
    this.to,
    this.threadId,
    this.parentThreadId,
    this.createdTime,
    this.expiresTime,
    this.body,
    this.attachments,
  });

  factory PlainTextMessage.fromJson(Map<String, dynamic> json) {
    final message = _$PlainTextMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  @override
  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$PlainTextMessageToJson(this));

  // https://identity.foundation/didcomm-messaging/spec/#message-layer-addressing-consistency
  void validateConsistencyWithEncryptedMessage({
    required List<Recipient>? recipients,
    required String? encryptionKeyId,
  }) {
    _validateFromHeader(
      encryptionKeyId: encryptionKeyId,
    );

    _validateToHeader(
      recipientsFromEncryptedMessage: recipients,
    );
  }

  // https://identity.foundation/didcomm-messaging/spec/#message-layer-addressing-consistency
  void validateConsistencyWithSignedMessage({
    required List<Signature>? signatures,
  }) {
    _validateFromHeader(
      signatureKeyIds: signatures
          ?.map(
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
          'to header is required if a Plain Message is inside of Encrypted Message',
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
      (signatureKeyId) => getDidFromId(signatureKeyId),
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
