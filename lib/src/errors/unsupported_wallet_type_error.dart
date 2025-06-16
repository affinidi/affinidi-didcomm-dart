import 'package:ssi/ssi.dart';

class UnsupportedWalletTypeError extends UnsupportedError {
  UnsupportedWalletTypeError(Wallet wallet)
      : super(
            'Wallet type ${wallet.runtimeType} is not supported for this operation.');
}
