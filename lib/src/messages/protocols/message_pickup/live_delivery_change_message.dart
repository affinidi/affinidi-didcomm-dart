import 'message_pickup_message/message_pickup_message.dart';

/// Represents a DIDComm Message Pickup 3.0 Live Delivery Change message as defined in
/// [DIDComm Messaging Spec, Message Pickup Protocol 3.0](https://didcomm.org/messagepickup/3.0).
///
/// This message is used to request or change the live delivery mode for message pickup.
class LiveDeliveryChangeMessage extends MessagePickupMessage {
  /// Indicates whether live delivery is requested (true) or not (false).
  ///
  /// See [DIDComm Message Pickup Protocol 3.0](https://didcomm.org/messagepickup/3.0)
  /// for the semantics of the `live_delivery` field.
  final bool liveDelivery;

  /// Constructs a [LiveDeliveryChangeMessage].
  ///
  /// [id]: Unique identifier for the message.
  /// [to]: List of recipient DIDs.
  /// [liveDelivery]: Whether live delivery is requested.
  /// [from]: Sender's DID.
  /// [expiresTime]: Optional expiration time for the message.
  /// [returnRoute]: Optional return route header value.
  LiveDeliveryChangeMessage({
    required super.id,
    required super.to,
    required this.liveDelivery,
    required super.from,
    super.expiresTime,
    super.returnRoute,
  }) : super(
          type: Uri.parse(
            'https://didcomm.org/messagepickup/3.0/live-delivery-change',
          ),
          body: {'live_delivery': liveDelivery},
        );

  /// Creates a [LiveDeliveryChangeMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the message.
  factory LiveDeliveryChangeMessage.fromJson(Map<String, dynamic> json) {
    final plainTextMessage = MessagePickupMessage.fromJson(json);
    return LiveDeliveryChangeMessage(
      id: plainTextMessage.id,
      to: plainTextMessage.to,
      liveDelivery: plainTextMessage.body?['live_delivery'] as bool? ?? false,
      from: plainTextMessage.from,
    );
  }
}
