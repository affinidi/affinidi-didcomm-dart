import 'dart:typed_data';

import 'package:didcomm/src/extensions/extensions.dart';
import 'package:elliptic/elliptic.dart' as ec;

import '../jwks/jwks.dart';
import '../messages/algorithm_types/algorithms_types.dart';
import '../messages/jwm/jwe_header.dart';
import 'ecdh_1pu.dart';

abstract class ECDHProfile {
  static ECDH1PU_Elliptic buildElliptic({
    required ec.PublicKey walletPublicKey,
    required JweHeader jweHeader,
    required List<int> authenticationTag,
    required Jwk jwk,
  }) {
    return ECDH1PU_Elliptic(
      publicKye1: jwk.toPublicKeyFromPoint(),
      publicKye2: walletPublicKey,
      authenticationTag: authenticationTag,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1PU,
      jweHeader: jweHeader,
    );
  }

  static ECDH1PU_X25519 buildX25519({
    required Uint8List walletPublicKeyBytes,
    required List<int> authenticationTag,
    required KeyWrappingAlgorithm keyWrappingAlgorithm,
    required JweHeader jweHeader,
    required Jwk jwk,
  }) {
    if (jwk.x == null) {
      throw ArgumentError('x is required', 'x');
    }

    return ECDH1PU_X25519(
      publicKeyBytes1: jwk.x!,
      publicKeyBytes2: walletPublicKeyBytes,
      authenticationTag: authenticationTag,
      keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1PU,
      jweHeader: jweHeader,
    );
  }

  Uint8List encryptData({
    required Uint8List walletPrivateKeyBytes,
    required Uint8List data,
  });

  Uint8List decryptData({
    required Uint8List walletPrivateKeyBytes,
    required Uint8List data,
  });
}
