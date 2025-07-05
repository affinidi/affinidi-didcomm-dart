import 'package:ssi/ssi.dart';

/// Represents a DIDComm service endpoint, containing information about accepted protocols, routing keys, and the endpoint URI.
class DidcommServiceEndpoint {
  /// List of accepted protocol types for this service endpoint.
  final List<String> accept;

  /// List of routing keys used for message routing to this endpoint.
  final List<String> routingKeys;

  /// The URI of the service endpoint.
  final String uri;

  /// Creates a new instance of [DidcommServiceEndpoint].
  ///
  /// [accept] is a list of accepted protocol types.
  /// [routingKeys] is a list of routing keys for message routing.
  /// [uri] is the endpoint URI.
  DidcommServiceEndpoint({
    required this.accept,
    required this.routingKeys,
    required this.uri,
  });

  /// This factory constructor parses the provided [mapEndpoint] and initializes the corresponding
  /// fields of the [DidcommServiceEndpoint] object. It is typically used when deserializing
  /// endpoint data received in a map format, such as from JSON.
  factory DidcommServiceEndpoint.fromMapEndpoint(
    MapEndpoint mapEndpoint,
  ) {
    final data = mapEndpoint.data;

    return DidcommServiceEndpoint(
      accept: data['accept'] != null
          ? (data['accept'] as List<dynamic>).cast<String>()
          : [],
      routingKeys: data['routingKeys'] != null
          ? (data['routingKeys'] as List<dynamic>).cast<String>()
          : [],
      uri: data['uri'] as String,
    );
  }
}
