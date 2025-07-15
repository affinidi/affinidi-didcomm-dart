import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../../annotations/own_json_properties.dart';
import '../../attachments/attachment.dart';
import '../../core.dart';

part 'out_of_band_message.g.dart';
part 'out_of_band_message.own_json_props.g.dart';

/// Represents a DIDComm Out-of-Band 2.0 Invitation message as defined in
/// [DIDComm Messaging Spec, Out-of-Band Protocol 2.0](https://identity.foundation/didcomm-messaging/spec/#out-of-band-messages).
///
/// This message is used to initiate a DIDComm interaction by inviting another party
/// to establish a connection or exchange messages out-of-band.
@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OutOfBandMessage extends PlainTextMessage {
  /// Constructs an [OutOfBandMessage].
  ///
  /// [id]: Unique identifier for the message.
  /// [from]: The sender's DID.
  /// [attachments]: Optional list of attachments (e.g., handshake protocols, requests).
  /// [body]: Optional message body.
  OutOfBandMessage({
    required super.id,
    required super.from,
    super.attachments,
    super.body,
  }) : super(
          type: Uri.parse('https://didcomm.org/out-of-band/2.0/invitation'),
        );

  /// The maximum allowed length for the generated OOB URL.
  static const maxUrlCharactersLength = 2048;

  /// The query parameter name used to encode the OOB message in a URL.
  static const oobQueryParam = 'oob';

  /// Converts the [OutOfBandMessage] to a URL according to the DIDComm spec.
  ///
  /// [origin]: The base URL to use as the origin (e.g., https://example.com). Must be a valid, non-empty absolute URL.
  ///
  /// Throws [ArgumentError] if [origin] is empty or invalid.
  /// Throws [FormatException] if the resulting URL exceeds [maxUrlCharactersLength].
  Uri toURL({required String origin}) {
    if (origin.trim().isEmpty) {
      throw ArgumentError('Origin must not be empty');
    }
    final uri = Uri.tryParse(origin.trim());
    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
      throw ArgumentError('Origin must be a valid absolute URL');
    }
    final jsonEncodedMessage = jsonEncode(toJson());
    final base64EncodedMessage =
        base64Url.encode(utf8.encode(jsonEncodedMessage));

    final url = uri.replace(queryParameters: {
      ...uri.queryParameters,
      OutOfBandMessage.oobQueryParam: base64EncodedMessage,
    });

    final urlLength = url.toString().length;
    if (urlLength > maxUrlCharactersLength) {
      throw FormatException(
          'Resulting URL exceeds $maxUrlCharactersLength characters limit. Current length: $urlLength');
    }
    return url;
  }

  /// Parses a URL to extract the [OutOfBandMessage].
  ///
  /// [url]: The URL containing the OOB query parameter.
  ///
  /// Throws [FormatException] if the URL is invalid, missing the OOB parameter, or the parameter is not valid JSON.
  static OutOfBandMessage fromURL(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const FormatException('Invalid URL format');
    }

    final oobParam = uri.queryParameters[oobQueryParam];

    if (oobParam == null) {
      throw const FormatException(
        'URL does not contain the OOB query parameter',
      );
    }

    final encodedMessage = utf8.decode(base64Url.decode(oobParam));
    final jsonDecodedMessage = jsonDecode(encodedMessage);

    if (jsonDecodedMessage is! Map<String, dynamic>) {
      throw const FormatException(
        'Decoded OOB parameter is not a valid JSON object',
      );
    }

    return OutOfBandMessage.fromJson(jsonDecodedMessage);
  }

  /// Creates an [OutOfBandMessage] from a JSON map.
  ///
  /// [json]: The JSON map representing the Out-of-Band message.
  factory OutOfBandMessage.fromJson(Map<String, dynamic> json) {
    final message = _$OutOfBandMessageFromJson(json)
      ..assignCustomHeaders(
        json,
        _$ownJsonProperties,
      );

    return message;
  }

  /// Converts this [OutOfBandMessage] to a JSON map, including custom headers.
  @override
  Map<String, dynamic> toJson() => withCustomHeaders(
        {
          ...super.toJson(),
          ..._$OutOfBandMessageToJson(this),
        },
      );
}
