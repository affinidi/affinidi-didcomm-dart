import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:meta/meta.dart';

class DidcommMessage {
  DidcommMessage();

  String get mediaType => 'application/didcomm-plain+json';
  final Map<String, dynamic> _customHeaders = {};

  dynamic operator [](String key) => _customHeaders[key];
  void operator []=(String key, dynamic value) => _customHeaders[key] = value;

  static PlaintextMessage unpackPlainTextMessage({
    required DidcommMessage message,
    required Wallet wallet,
  }) {
    if (message is PlaintextMessage) {
      return message;
    }

    throw UnimplementedError();
  }

  static SignedMessage unpackSignedMessage({
    required DidcommMessage message,
    required Wallet wallet,
  }) {
    throw UnimplementedError();
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
