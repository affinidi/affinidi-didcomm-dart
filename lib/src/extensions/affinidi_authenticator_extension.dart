import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/mediator_client/mediator_service_type.dart';

extension AffinidiAuthenticatorExtension on MediatorClient {
  Future<String> authenticate({required String did}) async {
    final dio = didDocument.toDio(
      mediatorServiceType: MediatorServiceType.authentication,
    );

    final response = await dio.post(
      '/challenge',
      data: {'did': did},
    );

    final challenge = response.data!['data']['challenge'];
    return challenge;
  }
}
