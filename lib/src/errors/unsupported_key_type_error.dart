import 'package:ssi/ssi.dart';

/// Error thrown when an unsupported key type is encountered in DIDComm operations.
class UnsupportedKeyTypeError extends UnsupportedError {
  /// Constructs an [UnsupportedKeyTypeError].
  ///
  /// [keyType]: The unsupported key type.
  UnsupportedKeyTypeError(KeyType keyType) : super('$keyType is not supported');
}
