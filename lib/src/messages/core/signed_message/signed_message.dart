import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:ssi/ssi.dart';

import '../../../../didcomm.dart';
import '../../../annotations/own_json_properties.dart';
import '../../../common/did.dart';
import '../../../common/encoding.dart';
import '../../../extensions/extensions.dart';
import '../../jwm.dart';

part 'signed_message.g.dart';
part 'signed_message.own_json_props.g.dart';

/// Represents a DIDComm v2 Signed Message as defined in the DIDComm Messaging specification.
///
/// See: https://identity.foundation/didcomm-messaging/spec/#didcomm-signed-messages
@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SignedMessage extends DidcommMessage {
  /// The default media type for signed DIDComm messages as per the spec.
  static final mediaType = 'application/didcomm-signed+json';

  /// The base64url-encoded payload (the inner message).
  final String payload;

  /// List of signatures over the payload.
  final List<Signature> signatures;

  /// Constructs a [SignedMessage].
  ///
  /// [payload]: The base64url-encoded payload.
  /// [signatures]: List of signatures over the payload.
  SignedMessage({
    required this.payload,
    required this.signatures,
  });

  /// Packs a [DidcommMessage] into a [SignedMessage] using the provided [signer].
  ///
  /// [message]: The message to sign.
  /// [signer]: The signer to use for signing the message.
  ///
  /// Returns a [SignedMessage] containing the signed payload.
  static Future<SignedMessage> pack(
    DidcommMessage message, {
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

    final signedMessage = SignedMessage(
      payload: encodedPayload,
      signatures: signatures,
    );

    return signedMessage;
  }

  /// Unpacks the signed message and verifies signature, returning the inner message as a JSON map.
  /// Unlike [DidcommMessage.unpackToPlainTextMessage], this method does not recursively unpack nested messages, but
  /// returns the top most message from the payload.
  ///
  /// Throws an [Exception] if the signature is invalid.
  Future<Map<String, dynamic>> unpack() async {
    if (!(await areSignaturesValid())) {
      Exception('Invalid signature was found');
    }

    final payloadBytes = base64UrlDecodeWithPadding(payload);
    final innerMessage = json.decode(utf8.decode(payloadBytes));

    return innerMessage as Map<String, dynamic>;
  }

  /// Verifies all signatures in the message.
  ///
  /// Returns true if all signatures are valid, false otherwise.
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

  /// Checks if the given [message] map is a signed message by verifying required properties.
  static bool isSignedMessage(Map<String, dynamic> message) {
    return _$ownJsonProperties.every((prop) => message.containsKey(prop));
  }

  /// Creates a [SignedMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the signed message.
  factory SignedMessage.fromJson(Map<String, dynamic> json) {
    final message = _$SignedMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  /// Serializes the signed message to a JSON map, including custom headers.
  @override
  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$SignedMessageToJson(this));
}
