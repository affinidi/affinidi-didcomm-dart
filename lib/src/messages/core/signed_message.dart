import 'dart:convert';

import 'package:didcomm/src/annotations/own_json_properties.dart';
import 'package:didcomm/src/common/encoding.dart';
import 'package:didcomm/src/extensions/extensions.dart';
import 'package:didcomm/src/messages/core/plaintext_message.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ssi/ssi.dart';
import '../signatures/signature.dart';
import '../didcomm_message.dart';

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
    PlaintextMessage message, {
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
    for (final prop in _$ownJsonProperties) {
      if (!message.containsKey(prop)) {
        return false;
      }
    }

    return true;
  }

  factory SignedMessage.fromJson(Map<String, dynamic> json) {
    final message = _$SignedMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$SignedMessageToJson(this));
}
