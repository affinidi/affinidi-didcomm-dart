import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../../didcomm_message.dart';

part 'out_of_band_message.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OutOfBandMessage extends DidcommMessage {
  final Uri type;
  final String id;
  final String from;
  final String goal;
  final String goalCode;
  final Map<String, dynamic> body;
  final List<Map<String, dynamic>>? attachments;

  OutOfBandMessage({
    required this.id,
    required this.from,
    required this.goal,
    required this.goalCode,
    required this.body,
    this.attachments,
  }) : type = Uri.parse("https://didcomm.org/out-of-band/2.0/invitation");

  static const maxUrlCharactersLength = 2048;
  static const oobQueryParam = 'oob';

  /// Converts the OutOfBandMessage to a URL according to the DIDComm spec.
  /// [origin] must be a valid URL and non-empty, ie. https://example.com
  /// Throws [FormatException] if origin is invalid or URL exceeds 2048 chars.
  String toURL({required String origin}) {
    if (origin.trim().isEmpty) {
      throw ArgumentError('Origin must not be empty');
    }
    final uri = Uri.tryParse(origin.trim());
    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
      throw ArgumentError('Origin must be a valid absolute URL');
    }
    final jsonStr = jsonEncode(toJson());
    final compactJson = jsonStr.replaceAll(RegExp(r'\s+'), '');
    final encoded = base64Url.encode(utf8.encode(compactJson));

    final url = uri.replace(queryParameters: {
      ...uri.queryParameters,
      oobQueryParam: encoded,
    }).toString();
    if (url.length > maxUrlCharactersLength) {
      throw FormatException(
          'Resulting URL exceeds $maxUrlCharactersLength characters');
    }
    return url;
  }

  /// Parses a URL to extract the OutOfBandMessage.
  /// Throws [FormatException] if the URL is invalid or does not contain the OOB
  /// query parameter.
  static OutOfBandMessage fromURL(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw FormatException('Invalid URL format');
    }
    final oobParam = uri.queryParameters[oobQueryParam];
    if (oobParam == null) {
      throw FormatException('URL does not contain the OOB query parameter');
    }
    final decoded = utf8.decode(base64Url.decode(oobParam));
    final json = jsonDecode(decoded);
    if (json is! Map<String, dynamic>) {
      throw FormatException('Decoded OOB parameter is not a valid JSON object');
    }
    return OutOfBandMessage.fromJson(json);
  }

  factory OutOfBandMessage.fromJson(Map<String, dynamic> json) =>
      _$OutOfBandMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$OutOfBandMessageToJson(this);
}
