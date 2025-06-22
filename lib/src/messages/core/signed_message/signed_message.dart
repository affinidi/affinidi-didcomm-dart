import 'dart:convert';

import 'package:didcomm/src/common/did.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ssi/ssi.dart';

import '../../../../didcomm.dart';
import '../../jwm.dart';
import '../../../annotations/own_json_properties.dart';
import '../../../common/encoding.dart';
import '../../../extensions/extensions.dart';

part 'signed_message.g.dart';
part 'signed_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SignedMessage extends DidcommMessage {
  static final mediaType = 'application/didcomm-signed+json';

  final String payload;
  final List<Signature> signatures;

  SignedMessage({
    required this.payload,
    required this.signatures,
  });

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

    final signatures = [
      Signature(
        signature: await signer.sign(signingInput),
        protected: jwsHeader,
        header: SignatureHeader(keyId: signer.keyId),
      ),
    ];

    message.validateConsistencyWithSignedMessage(signatures: signatures);

    return SignedMessage(
      payload: encodedPayload,
      signatures: signatures,
    );
  }

  Future<Map<String, dynamic>> unpack() async {
    if (!(await areSignaturesValid())) {
      Exception('Invalid signature was found');
    }

    final payloadBytes = base64UrlDecodeWithPadding(payload);
    final innerMessage = json.decode(utf8.decode(payloadBytes));

    // TODO: check if it is Plain Text Message. decide if we support only Plain Text Message inside Singed Message
    PlainTextMessage.fromJson(innerMessage)
        .validateConsistencyWithSignedMessage(
      signatures: signatures,
    );

    return innerMessage;
  }

  // TODO: add issuer check
  Future<bool> areSignaturesValid() async {
    for (final signature in signatures) {
      final signatureScheme =
          SignatureScheme.fromString(signature.protected.algorithm);

      final verifier = await DidVerifier.create(
        algorithm: signatureScheme,
        issuerDid: getDidFromId(signature.header.keyId),
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

  @override
  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$SignedMessageToJson(this));
}
