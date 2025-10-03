import 'package:json_annotation/json_annotation.dart';

import '../../../../../didcomm.dart';

part 'message_pickup_message.g.dart';
part 'message_pickup_message.own_json_props.g.dart';

/// Represents a DIDComm Message Pickup Protocol 3.0 message as defined in
/// [DIDComm Messaging Spec, Message Pickup Protocol 3.0](https://didcomm.org/messagepickup/3.0).
///
/// This message is used to request or manage message pickup from a mediator.
@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MessagePickupMessage extends PlainTextMessage {
  /// The `return_route` header, indicating how responses should be routed.
  @JsonKey(name: 'return_route')
  final String returnRoute;

  /// Constructs a [MessagePickupMessage].
  ///
  /// [id]: Unique identifier for the message.
  /// [to]: List of recipient DIDs.
  /// [from]: Sender's DID.
  /// [type]: Message type URI.
  /// [body]: Message body as a map.
  /// [expiresTime]: Optional expiration time for the message.
  /// [returnRoute]: The return route header value (default: 'all').
  MessagePickupMessage({
    required super.id,
    required super.to,
    required super.from,
    required super.type,
    required super.body,
    super.createdTime,
    super.expiresTime,
    super.threadId,
    super.parentThreadId,
    super.acknowledged,
    super.pleaseAcknowledge,
    super.attachments,
    this.returnRoute = 'all',
  });

  /// Creates a [MessagePickupMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the message.
  factory MessagePickupMessage.fromJson(Map<String, dynamic> json) {
    final message = _$MessagePickupMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  /// Converts this [MessagePickupMessage] to a JSON map, including custom headers.
  @override
  Map<String, dynamic> toJson() => withCustomHeaders({
        ...super.toJson(),
        ..._$MessagePickupMessageToJson(this),
      });
}
