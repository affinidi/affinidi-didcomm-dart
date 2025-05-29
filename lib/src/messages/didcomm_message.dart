import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:meta/meta.dart';

class DidcommMessage {
  DidcommMessage();

  static final mediaType = 'application/didcomm-plain+json';
  final Map<String, dynamic> _customHeaders = {};

  dynamic operator [](String key) => _customHeaders[key];
  void operator []=(String key, dynamic value) => _customHeaders[key] = value;

  static Future<PlainTextMessage?> unpackToPlainTextMessage({
    required Map<String, dynamic> message,
    required Wallet recipientWallet,
  }) async {
    // TODO: add recursiv check for cases when there multiple encryption or signed leyars
    var currentMessage = message;

    if (EncryptedMessage.isEncryptedMessage(currentMessage)) {
      final encryptedMessage = EncryptedMessage.fromJson(currentMessage);
      currentMessage = await encryptedMessage.unpack(
        recipientWallet: recipientWallet,
      );
    }

    if (SignedMessage.isSignedMessage(currentMessage)) {
      final signedMessage = SignedMessage.fromJson(currentMessage);
      currentMessage = await signedMessage.unpack();
    }

    return PlainTextMessage.fromJson(currentMessage);
  }

  static Future<SignedMessage?> unpackToSignedMessage({
    required Map<String, dynamic> message,
    required Wallet recipientWallet,
  }) async {
    // TODO: add recursiv check for cases when there multiple encryption or signed leyars
    var currentMessage = message;

    if (EncryptedMessage.isEncryptedMessage(currentMessage)) {
      final encryptedMessage = EncryptedMessage.fromJson(currentMessage);
      currentMessage = await encryptedMessage.unpack(
        recipientWallet: recipientWallet,
      );
    }

    if (SignedMessage.isSignedMessage(currentMessage)) {
      return SignedMessage.fromJson(currentMessage);
    }

    return null;
  }

  @protected
  Map<String, dynamic> withCustomHeaders(Map<String, dynamic> json) {
    return {...json, ..._customHeaders};
  }

  @protected
  void assignCustomHeaders(Map<String, dynamic> json, List<String> ownHeaders) {
    final customHeaders = json.keys.where((key) => !ownHeaders.contains(key));

    for (final key in customHeaders) {
      this[key] = json[key];
    }
  }
}
