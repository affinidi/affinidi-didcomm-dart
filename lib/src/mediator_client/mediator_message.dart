/// The mediator message returned by mediator instance
class MediatorMessage {
  /// The DIDComm message
  final Map<String, dynamic> message;

  /// The id of the message
  final String messageId;

  /// The receive_id of the message.
  final String receiveId;

  /// The sendId of the message
  final String sendId;

  /// The mediator message returned by mediator instance
  MediatorMessage({
    required this.message,
    required this.messageId,
    required this.receiveId,
    required this.sendId,
  });
}
