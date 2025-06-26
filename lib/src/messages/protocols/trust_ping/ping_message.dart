import 'package:json_annotation/json_annotation.dart';
import '../../core/plain_text_message/plain_text_message.dart';

/// Represents a DIDComm v2 Trust Ping message as defined in the trust-ping protocol.
///
/// See: https://identity.foundation/didcomm-messaging/spec/#trust-ping-protocol-20
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PingMessage extends PlainTextMessage {
  /// Indicates whether a response is requested from the recipient.
  final bool responseRequested;

  /// Constructs a [PingMessage].
  ///
  /// [id]: Unique message identifier.
  /// [from]: Sender's DID.
  /// [to]: List of recipient DIDs (optional).
  /// [responseRequested]: Whether a response is requested (default: true).
  PingMessage({
    required super.id,
    required super.from,
    super.to,
    this.responseRequested = true,
  }) : super(
          type: Uri.parse('https://didcomm.org/trust-ping/2.0/ping'),
          body: {'response_requested': responseRequested},
        );

  /// Creates a [PingMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the ping message.
  factory PingMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = PlainTextMessage.fromJson(json);
    return PingMessage(
      id: plainTextMessage.id,
      to: plainTextMessage.to,
      from: plainTextMessage.from,
      responseRequested:
          plainTextMessage.body?['response_requested'] as bool? ?? false,
    );
  }
}
