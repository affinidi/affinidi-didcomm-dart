import 'live_delivery_change_message_options.dart';
import 'status_request_message_options.dart';

/// Options for configuring WebSocket-based DIDComm message pickup interactions.
///
/// This class allows customization of options for status request and live delivery change messages
/// when using a WebSocket transport with a mediator.
class WebSocketOptions {
  /// Options for the status request message sent over WebSocket.
  final StatusRequestMessageOptions statusRequestMessageOptions;

  /// Options for the live delivery change message sent over WebSocket.
  final LiveDeliveryChangeMessageOptions liveDeliveryChangeMessageOptions;

  /// Interval (in seconds) at which ping messages are sent to keep the
  /// WebSocket connection alive.
  final int pingIntervalInSeconds;

  /// Indicates whether the message should be deleted on the mediator right after it was received by the client (default: true).
  final bool deleteOnMediator;

  /// Constructs [WebSocketOptions].
  ///
  /// [statusRequestMessageOptions]: Options for status request messages (default: const StatusRequestMessageOptions()).
  /// [liveDeliveryChangeMessageOptions]: Options for live delivery change messages (default: const LiveDeliveryChangeMessageOptions()).
  const WebSocketOptions({
    this.statusRequestMessageOptions = const StatusRequestMessageOptions(),
    this.liveDeliveryChangeMessageOptions =
        const LiveDeliveryChangeMessageOptions(),
    this.pingIntervalInSeconds = 30,
    this.deleteOnMediator = true,
  });
}
