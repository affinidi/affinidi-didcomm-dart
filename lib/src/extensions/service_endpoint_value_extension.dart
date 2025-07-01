import 'package:ssi/ssi.dart';

extension ServiceEndpointValueExtension on ServiceEndpointValue {
  List<MapEndpoint> getUnifiedServiceEndpoints() {
    if (this is StringEndpoint) {
      return [
        MapEndpoint({
          'uri': (this as StringEndpoint).url,
        })
      ];
    }

    if (this is MapEndpoint) {
      return [
        this as MapEndpoint,
      ];
    }

    if (this is SetEndpoint) {
      return (this as SetEndpoint)
          .endpoints
          .expand(
            (endpointValue) => endpointValue.getUnifiedServiceEndpoints(),
          )
          .toList();
    }

    throw UnsupportedError('Endpoint type is not supported: $runtimeType');
  }
}
