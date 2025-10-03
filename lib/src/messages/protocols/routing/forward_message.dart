import '../../../../../didcomm.dart';

/// Represents a DIDComm Routing Protocol 2.0 Forward message as defined in
/// [DIDComm Messaging Spec, Routing Protocol 2.0](https://identity.foundation/didcomm-messaging/spec/#routing-protocol-20).
///
/// The Forward message is used to instruct a mediator to forward an attached message
/// to the next recipient in the routing chain.
class ForwardMessage extends PlainTextMessage {
  /// The URI representing the message type.
  /// This is used to identify the specific protocol message type within DIDComm.
  static final messageType = Uri.parse(
    'https://didcomm.org/routing/2.0/forward',
  );

  /// The DID of the next recipient to which the attached message should be forwarded.
  ///
  /// See [DIDComm Routing Protocol 2.0](https://identity.foundation/didcomm-messaging/spec/#routing-protocol-20)
  /// for the semantics of the `next` field.
  final String next;

  /// Constructs a [ForwardMessage].
  ///
  /// [id]: Unique identifier for the message.
  /// [to]: List of recipient DIDs (should contain the mediator's DID).
  /// [attachments]: List of attachments, typically containing the message to be forwarded.
  /// [next]: The DID of the next recipient in the routing chain.
  /// [expiresTime]: Optional expiration time for the message.
  /// [from]: Optional sender DID.
  ForwardMessage({
    required super.id,
    required super.to,
    required super.attachments,
    required this.next,
    super.from,
    super.createdTime,
    super.expiresTime,
    super.threadId,
    super.parentThreadId,
    super.acknowledged,
    super.pleaseAcknowledge,
  }) : super(
          type: messageType,
          body: {'next': next},
        );

  /// Creates a [ForwardMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the Forward message.
  factory ForwardMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = PlainTextMessage.fromJson(json);
    return ForwardMessage(
      id: plainTextMessage.id,
      to: plainTextMessage.to,
      next: plainTextMessage.body?['next'] as String,
      attachments: plainTextMessage.attachments,
    );
  }
}
