import 'package:json_annotation/json_annotation.dart';
import '../../../../didcomm.dart';
import '../../../annotations/own_json_properties.dart';

part 'ping_response_message.g.dart';
part 'ping_response_message.own_json_props.g.dart';

/// Represents a DIDComm v2 Trust Ping Response message as defined in the trust-ping protocol.
///
/// See: https://identity.foundation/didcomm-messaging/spec/#ping-response
@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PingResponseMessage extends PlainTextMessage {
  /// Constructs a [PingResponseMessage].
  ///
  /// [id]: Unique message identifier.
  /// [threadId]: Thread ID referencing the original ping message.
  /// [to]: List of recipient DIDs (optional).
  /// [from]: Sender's DID (optional).
  PingResponseMessage({
    required super.id,
    required threadId,
    super.to,
    super.from,
  }) : super(
          type: Uri.parse('https://didcomm.org/trust-ping/2.0/ping-response'),
        );

  /// Creates a [PingResponseMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the ping response message.
  factory PingResponseMessage.fromJson(Map<String, dynamic> json) {
    final message = _$PingResponseMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  /// Converts this [PingResponseMessage] to a JSON map, including custom headers.
  @override
  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$PingResponseMessageToJson(this));
}
