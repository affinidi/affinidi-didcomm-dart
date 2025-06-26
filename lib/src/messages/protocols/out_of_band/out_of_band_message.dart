import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../../annotations/own_json_properties.dart';
import '../../attachments/attachment.dart';
import '../../core.dart';

part 'out_of_band_message.g.dart';
part 'out_of_band_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OutOfBandMessage extends PlainTextMessage {
  OutOfBandMessage({
    required super.id,
    required super.from,
    super.attachments,
    super.body,
  }) : super(
          type: Uri.parse('https://didcomm.org/out-of-band/2.0/invitation'),
        );

  static const maxUrlCharactersLength = 2048;
  static const oobQueryParam = 'oob';

  /// Converts the OutOfBandMessage to a URL according to the DIDComm spec.
  /// [origin] must be a valid URL and non-empty, ie. https://example.com
  /// Throws [FormatException] if origin is invalid or URL exceeds 2048 chars.
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

  /// Parses a URL to extract the OutOfBandMessage.
  /// Throws [FormatException] if the URL is invalid or does not contain the OOB
  /// query parameter.
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

  factory OutOfBandMessage.fromJson(Map<String, dynamic> json) {
    final message = _$OutOfBandMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  @override
  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$OutOfBandMessageToJson(this));
}
