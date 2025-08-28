import '../../messages/algorithm_types/algorithms_types.dart';

/// Options for configuring protection and cryptographic algorithms for DIDComm messages.
///
/// This class allows specifying whether a message should be signed, encrypted, and which algorithms to use.
class MessageOptions {
  /// Whether the message should be signed.
  ///
  /// Default is false.
  final bool shouldSign;

  /// Whether the message should be encrypted.
  ///
  /// Default is false.
  final bool shouldEncrypt;

  /// The key wrapping algorithm to use for encryption.
  ///
  /// Default is [KeyWrappingAlgorithm.ecdhEs].
  final KeyWrappingAlgorithm keyWrappingAlgorithm;

  /// The encryption algorithm to use for message content.
  ///
  /// Default is [EncryptionAlgorithm.a256cbc].
  final EncryptionAlgorithm encryptionAlgorithm;

  /// Constructs [MessageOptions].
  ///
  /// [shouldSign]: Whether the message should be signed (default: false).
  /// [shouldEncrypt]: Whether the message should be encrypted (default: true).
  /// [keyWrappingAlgorithm]: The key wrapping algorithm to use (default: [KeyWrappingAlgorithm.ecdhEs]).
  /// [encryptionAlgorithm]: The encryption algorithm to use (default: [EncryptionAlgorithm.a256cbc]).
  const MessageOptions({
    this.shouldSign = false,
    this.shouldEncrypt = true,
    this.keyWrappingAlgorithm = KeyWrappingAlgorithm.ecdhEs,
    this.encryptionAlgorithm = EncryptionAlgorithm.a256cbc,
  });
}
