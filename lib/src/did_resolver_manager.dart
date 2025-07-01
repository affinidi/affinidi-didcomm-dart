import 'package:ssi/ssi.dart';

typedef DIDResolver = Future<DidDocument> Function(
  String did, {
  String? resolverAddress,
});

class DidResolverManager {
  static DIDResolver _didResolver = UniversalDIDResolver.resolve;
  static String? _resolverAddress;

  static void setResolver(DIDResolver didResolver) {
    DidResolverManager._didResolver = didResolver;
  }

  static void setResolverAddress(String resolverAddress) {
    _resolverAddress = resolverAddress;
  }

  static Future<DidDocument> resolve(String did) {
    return _didResolver(did, resolverAddress: _resolverAddress);
  }
}
