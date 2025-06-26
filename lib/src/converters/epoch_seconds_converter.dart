import 'package:json_annotation/json_annotation.dart';

/// A [JsonConverter] for encoding and decoding [DateTime] objects as epoch seconds (UTC).
///
/// This converter is used to serialize and deserialize timestamps in DIDComm messages.
class EpochSecondsConverter implements JsonConverter<DateTime, int> {
  /// Creates an [EpochSecondsConverter].
  const EpochSecondsConverter();

  /// Decodes a [DateTime] from an integer representing seconds since the Unix epoch (UTC).
  ///
  /// [json]: The integer value representing epoch seconds.
  /// Returns the decoded [DateTime] in UTC.
  @override
  DateTime fromJson(int json) =>
      DateTime.fromMillisecondsSinceEpoch(json * 1000, isUtc: true);

  /// Encodes a [DateTime] as an integer representing seconds since the Unix epoch (UTC).
  ///
  /// [object]: The [DateTime] to encode.
  /// Returns the integer value representing epoch seconds.
  @override
  int toJson(DateTime object) => object.toUtc().millisecondsSinceEpoch ~/ 1000;
}
