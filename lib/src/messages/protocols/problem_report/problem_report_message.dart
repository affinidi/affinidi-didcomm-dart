import 'package:json_annotation/json_annotation.dart';
import '../../didcomm_message.dart';

part 'problem_report_message.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ProblemReportMessage extends DidcommMessage {
  ProblemReportMessage();

  factory ProblemReportMessage.fromJson(Map<String, dynamic> json) =>
      _$ProblemReportMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProblemReportMessageToJson(this);
}
