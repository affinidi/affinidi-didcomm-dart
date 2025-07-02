import 'package:ssi/ssi.dart';

extension DidControllerExtension on DidController {
  Future<KeyPair> getKeyPairByDidKeyId(String didKeyId) async {
    final key = await getKey(didKeyId);
    return key.keyPair;
  }
}
