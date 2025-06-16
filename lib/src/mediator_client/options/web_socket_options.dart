import 'status_request_message_options.dart';
import 'live_delivery_change_message_options.dart';

class WebSocketOptions {
  final StatusRequestMessageOptions statusRequestMessageOptions;
  final LiveDeliveryChangeMessageOptions liveDeliveryChangeMessageOptions;

  const WebSocketOptions({
    this.statusRequestMessageOptions = const StatusRequestMessageOptions(),
    this.liveDeliveryChangeMessageOptions =
        const LiveDeliveryChangeMessageOptions(),
  });
}
