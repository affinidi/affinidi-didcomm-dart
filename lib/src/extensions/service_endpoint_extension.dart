import 'package:ssi/ssi.dart';

import '../common/didcomm_service_endpoint.dart';
import 'service_endpoint_value_extension.dart';

/// Extension on [ServiceEndpoint] to extract DIDComm service endpoints.
extension ServiceEndpointExtension on ServiceEndpoint {
  /// Returns a list of [DidcommServiceEndpoint] objects parsed from the service endpoint.
  List<DidcommServiceEndpoint> getDidcommServiceEndpoints() {
    return serviceEndpoint
        .getUnifiedServiceEndpoints()
        .map(DidcommServiceEndpoint.fromMapEndpoint)
        .toList();
  }
}
