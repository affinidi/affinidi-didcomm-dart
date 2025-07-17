import '../../didcomm.dart';

/// Thrown when A256GCM or XC20P is used with authcrypt (ECDH-1PU) which is not allowed by DIDComm specification.
///
/// This error indicates that the provided [EncryptionAlgorithm] is incompatible with the
/// [KeyWrappingAlgorithm.ecdh1Pu] (authenticated encryption). Only A256CBC-HS512
/// is allowed for use with authcrypt according to the DIDComm specification.
class IncompatibleEncryptionAlgorithmWithAuthcrypt extends UnsupportedError {
  /// Creates an [IncompatibleEncryptionAlgorithmWithAuthcrypt] error for the given [encryptionAlgorithm].
  ///
  /// The error message will indicate which algorithm is not supported with ECDH-1PU.
  IncompatibleEncryptionAlgorithmWithAuthcrypt(
    EncryptionAlgorithm encryptionAlgorithm,
  ) : super(
          'The encryption algorithm ${encryptionAlgorithm.value} can not be used with ${KeyWrappingAlgorithm.ecdh1Pu.value}. Only ${EncryptionAlgorithm.a256cbc.value} is allowed for use with authcrypt according to the DIDComm specification.',
        );
}
