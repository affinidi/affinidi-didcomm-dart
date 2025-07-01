import 'package:ssi/ssi.dart';

class DidcommServiceEndpoint {
  final List<String> accept;
  final List<String> routingKeys;
  final String uri;

  DidcommServiceEndpoint({
    required this.accept,
    required this.routingKeys,
    required this.uri,
  });

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
