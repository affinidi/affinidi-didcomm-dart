import '../../../../didcomm.dart';

/// Represents a DIDComm message that carries a [TrustTaskDocument], as defined
/// by the Trust Tasks DIDComm binding.
///
/// The sender and recipient are taken from the document's issuer and recipient,
/// so the DIDComm addressing always matches the Trust Task.
///
/// See: https://trusttasks.org
class TrustTaskMessage extends PlainTextMessage {
  /// The URI representing the message type.
  /// This is used to identify the specific protocol message type within DIDComm.
  static final messageType = Uri.parse(
    'https://trusttasks.org/binding/didcomm/0.1/envelope',
  );

  /// The Trust Task document carried in the message body.
  final TrustTaskDocument document;

  /// Constructs a [TrustTaskMessage].
  ///
  /// [id]: Unique message identifier.
  /// [document]: The Trust Task document to carry.
  /// [createdTime]: Message creation time (optional).
  /// [expiresTime]: Message expiration time (optional).
  /// [threadId]: Thread ID for message threading (optional).
  /// [parentThreadId]: Parent thread ID for nested threading (optional).
  /// [pleaseAcknowledge]: Message IDs to acknowledge (optional).
  /// [acknowledged]: Message IDs acknowledged by this message (optional).
  /// [attachments]: List of attachments (optional).
  TrustTaskMessage({
    required super.id,
    required this.document,
    super.createdTime,
    super.expiresTime,
    super.threadId,
    super.parentThreadId,
    super.pleaseAcknowledge,
    super.acknowledged,
    super.attachments,
  }) : super(
          type: messageType,
          from: document.issuer,
          to: [document.recipient],
          body: document.toJson(),
        );

  /// Creates a [TrustTaskMessage] from a JSON map, e.g. a response a mediator
  /// stored in the inbox.
  ///
  /// [json]: The JSON map representing the message.
  ///
  /// Throws [FormatException] if the message is not a Trust Task message, has
  /// no valid Trust Task document as its body, or if its sender or recipients
  /// do not match the document's issuer and recipient.
  factory TrustTaskMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = PlainTextMessage.fromJson(json);

    if (!isTrustTask(plainTextMessage)) {
      throw FormatException(
        'Not a Trust Task message: ${plainTextMessage.type}',
      );
    }

    final body = plainTextMessage.body;

    if (body == null) {
      throw const FormatException('Trust Task message has no body');
    }

    final document = TrustTaskDocument.fromJson(body);

    // The message's addressing is taken from the document, so a mismatch would
    // attribute the task to a party other than the DIDComm sender.
    if (plainTextMessage.from != document.issuer) {
      throw const FormatException(
        'Trust Task message sender does not match the document issuer',
      );
    }

    final to = plainTextMessage.to;

    if (to == null || to.length != 1 || to.single != document.recipient) {
      throw const FormatException(
        'Trust Task message must be addressed to the document recipient only',
      );
    }

    return TrustTaskMessage(
      id: plainTextMessage.id,
      document: document,
      createdTime: plainTextMessage.createdTime,
      expiresTime: plainTextMessage.expiresTime,
      threadId: plainTextMessage.threadId,
      parentThreadId: plainTextMessage.parentThreadId,
      pleaseAcknowledge: plainTextMessage.pleaseAcknowledge,
      acknowledged: plainTextMessage.acknowledged,
      attachments: plainTextMessage.attachments,
    );
  }

  /// Returns `true` if [message] is a Trust Task message, e.g. a response
  /// a mediator stored in the inbox after processing a Trust Task.
  static bool isTrustTask(PlainTextMessage message) =>
      message.type == messageType;
}
