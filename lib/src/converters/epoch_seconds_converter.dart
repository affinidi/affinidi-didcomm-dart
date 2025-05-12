import 'package:json_annotation/json_annotation.dart';

class EpochSecondsConverter implements JsonConverter<DateTime, int> {
  const EpochSecondsConverter();

  @override
  DateTime fromJson(int json) =>
      DateTime.fromMillisecondsSinceEpoch(json * 1000, isUtc: true);

  @override
  int toJson(DateTime object) => object.toUtc().millisecondsSinceEpoch ~/ 1000;
}
