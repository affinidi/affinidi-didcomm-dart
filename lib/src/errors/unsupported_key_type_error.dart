import 'package:ssi/ssi.dart';

class UnsupportedKeyTypeError extends UnsupportedError {
  UnsupportedKeyTypeError(KeyType keyType) : super('$keyType is not supported');
}
