import 'package:ssi/ssi.dart';

import '../common/didcomm_service_endpoint.dart';
import 'service_endpoint_value_extension.dart';

extension ServiceEndpointExtension on ServiceEndpoint {
  List<DidcommServiceEndpoint> getDidcommServiceEndpoints() {
    return serviceEndpoint
        .getUnifiedServiceEndpoints()
        .map(DidcommServiceEndpoint.fromMapEndpoint)
        .toList();
  }
}
