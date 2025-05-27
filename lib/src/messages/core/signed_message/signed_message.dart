import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:ssi/ssi.dart';

import 'signature.dart';
import '../../didcomm_message.dart';
import '../../../annotations/own_json_properties.dart';
import '../../../common/encoding.dart';
import '../../../extensions/extensions.dart';
import '../plain_text_message/plain_text_message.dart';

part 'signed_message.g.dart';
part 'signed_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false)
class SignedMessage extends DidcommMessage {
  @override
  String get mediaType => 'application/didcomm-signed+json';

  final String payload;
  final List<Signature> signatures;

  SignedMessage({required this.payload, required this.signatures});

  static Future<SignedMessage> pack(
    PlainTextMessage message, {
    required Wallet wallet,
    required String keyId,
  }) async {
    return SignedMessage(
      payload: base64UrlEncode(message.toJsonBytes()),
      signatures: [],
    );
  }

  Future<Map<String, dynamic>> unpack({required Wallet wallet}) async {
    final payloadBytes = base64UrlDecodeWithPadding(payload);
    return json.decode(utf8.decode(payloadBytes));
  }

  static bool isSignedMessage(Map<String, dynamic> message) {
    return _$ownJsonProperties.every((prop) => message.containsKey(prop));
  }

  factory SignedMessage.fromJson(Map<String, dynamic> json) {
    final message = _$SignedMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$SignedMessageToJson(this));
}
