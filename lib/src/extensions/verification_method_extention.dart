import 'package:collection/collection.dart';
import 'package:ssi/ssi.dart' hide Jwk;

import '../../didcomm.dart';

/// Extension methods for the [VerificationMethod] class, providing additional
/// functionality and utilities related to verification methods in DIDComm.
extension VerificationMethodExtention on VerificationMethod {
  /// Converts this [VerificationMethod] to a [Jwk] object.
  ///
  /// Returns the [Jwk] representation of the verification method.
  Jwk toJwk() {
    final jwk = asJwk().toJson();
    return Jwk.fromJson(jwk);
  }

  /// Returns the DID key identifier by prefixing the [id] with [controller] if [id] starts with '#',
  /// otherwise returns [id] as is.
  ///
  /// This is useful for resolving relative key references within a DID document.
  String get didKeyId => id.startsWith('#') ? '$controller$id' : id;
}

/// Extension methods for [List<VerificationMethod>] to support curve-based lookup.
extension VerificationMethodListExtention on List<VerificationMethod> {
  /// Returns the first [VerificationMethod] in the list with the given [curve].
  ///
  /// [curve]: The [CurveType] to match.
  /// Throws [NotFoundVerificationMethodByCurveError] if no matching verification method is found.
  VerificationMethod firstWithCurve(CurveType curve) {
    final match = firstWhereOrNull(
      (verificationMethod) => verificationMethod.toJwk().curve == curve,
    );

    if (match == null) {
      throw NotFoundVerificationMethodByCurveError(curve);
    }

    return match;
  }
}
