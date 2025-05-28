import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:ssi/ssi.dart';

import '../../jwm.dart';
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
  static final mediaType = 'application/didcomm-signed+json';

  final String payload;
  final List<Signature> signatures;

  SignedMessage({required this.payload, required this.signatures});

  static Future<SignedMessage> pack(
    PlainTextMessage message, {
    required DidSigner signer,
  }) async {
    final jwsHeader = JwsHeader(
      mimeType: mediaType,
      // TODO: clarify alg with SSI
      algorithm: signer.signatureScheme.alg!,
      curve: signer.signatureScheme.crv,
    );

    final encodedPayload = base64UrlEncodeNoPadding(message.toJsonBytes());
    final encodedHeader = base64UrlEncodeNoPadding(jwsHeader.toJsonBytes());

    final signingInput = ascii.encode('$encodedHeader.$encodedPayload');
    final signature = await signer.sign(signingInput);

    return SignedMessage(
      payload: encodedPayload,
      signatures: [
        Signature(
          signature: signature,
          protected: jwsHeader,
          header: SignatureHeader(keyId: signer.keyId),
        )
      ],
    );
  }

  Future<Map<String, dynamic>> unpack() async {
    if (!(await areSignaturesValid())) {
      Exception('Invalid signature was found');
    }

    final payloadBytes = base64UrlDecodeWithPadding(payload);
    return json.decode(utf8.decode(payloadBytes));
  }

  Future<bool> areSignaturesValid() async {
    for (final signature in signatures) {
      final signatureScheme =
          SignatureScheme.fromString(signature.protected.algorithm);

      final verifier = await DidVerifier.create(
        algorithm: signatureScheme,
        issuerDid: signature.header.keyId.split('#').first,
        kid: signature.header.keyId,
      );

      final jwsHeader = JwsHeader(
        mimeType: mediaType,
        algorithm: signature.protected.algorithm,
        curve: signature.protected.curve,
      );

      final encodedPayload = base64UrlEncodeNoPadding(toJsonBytes());
      final encodedHeader = base64UrlEncodeNoPadding(jwsHeader.toJsonBytes());

      final isValid = verifier.verify(
          ascii.encode('$encodedHeader.$encodedPayload'), signature.signature);

      if (!isValid) {
        return false;
      }
    }

    return true;
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
