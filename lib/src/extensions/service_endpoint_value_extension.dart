import 'package:ssi/ssi.dart';


/// Extension on [ServiceEndpointValue] to normalize and extract all endpoint representations as [MapEndpoint]s.
extension ServiceEndpointValueExtension on ServiceEndpointValue {
  /// Returns a list of [MapEndpoint] objects representing all possible forms of the service endpoint.
  ///
  /// - If the value is a [StringEndpoint], it is converted to a [MapEndpoint] with a `uri` key.
  /// - If the value is already a [MapEndpoint], it is returned as a single-element list.
  /// - If the value is a [SetEndpoint], all contained endpoints are recursively normalized and flattened.
  ///
  /// Throws [UnsupportedError] if the endpoint type is not supported.
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
