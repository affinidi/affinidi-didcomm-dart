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

  /// Constructs [WebSocketOptions].
  ///
  /// [statusRequestMessageOptions]: Options for status request messages (default: const StatusRequestMessageOptions()).
  /// [liveDeliveryChangeMessageOptions]: Options for live delivery change messages (default: const LiveDeliveryChangeMessageOptions()).
  const WebSocketOptions({
    this.statusRequestMessageOptions = const StatusRequestMessageOptions(),
    this.liveDeliveryChangeMessageOptions =
        const LiveDeliveryChangeMessageOptions(),
  });
}
