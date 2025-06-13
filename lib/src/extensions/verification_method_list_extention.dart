import 'package:ssi/ssi.dart' hide Jwk;

import '../jwks/jwks.dart';

extension VerificationMethodListExtention on List<VerificationMethod> {
  Jwks toJwks() {
    return Jwks(
        keys: map(
      (keyAgreement) {
        final jwk = keyAgreement.asJwk().toJson();
        // TODO: kid is not available in the Jwk anymore. clarify with the team
        jwk['kid'] = keyAgreement.id;
        return Jwk.fromJson(jwk);
      },
    ).toList());
  }
}
