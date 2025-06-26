import '../../core.dart';
import 'message_pickup_message/message_pickup_message.dart';

/// Represents a DIDComm Message Pickup 3.0 Status Request message as defined in
/// [DIDComm Messaging Spec, Message Pickup Protocol 3.0](https://didcomm.org/messagepickup/3.0/).
///
/// This message is used to request the status of pending messages for a specific recipient DID.
class StatusRequestMessage extends MessagePickupMessage {
  /// The DID of the recipient whose message status is being requested.
  ///
  /// See [DIDComm Message Pickup Protocol 3.0](https://didcomm.org/messagepickup/3.0/)
  /// for the semantics of the `recipient_did` field.
  final String recipientDid;

  /// Constructs a [StatusRequestMessage].
  ///
  /// [id]: Unique identifier for the message.
  /// [to]: List of recipient DIDs.
  /// [recipientDid]: The DID whose message status is being requested.
  /// [from]: Sender's DID.
  /// [expiresTime]: Optional expiration time for the message.
  /// [returnRoute]: Optional return route header value.
  StatusRequestMessage({
    required super.id,
    required super.to,
    required this.recipientDid,
    required super.from,
    super.expiresTime,
    super.returnRoute,
  }) : super(
          type: Uri.parse(
            'https://didcomm.org/messagepickup/3.0/status-request',
          ),
          body: {'recipient_did': recipientDid},
        );

  /// Creates a [StatusRequestMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the message.
  factory StatusRequestMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = PlainTextMessage.fromJson(json);
    return StatusRequestMessage(
      id: plainTextMessage.id,
      to: plainTextMessage.to,
      recipientDid: plainTextMessage.body?['recipient_did'] as String,
      from: plainTextMessage.from,
    );
  }
}
