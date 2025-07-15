import 'package:json_annotation/json_annotation.dart';

import '../../../../didcomm.dart';

part 'problem_report_body.g.dart';

/// The body of a DIDComm problem report message, as defined by the DIDComm Messaging specification.
///
/// Contains information about the problem code, optional human-readable comment, arguments for message formatting,
/// and an optional escalation contact.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ProblemReportBody {
  /// The problem code describing the error or issue encountered.
  @ProblemCodeConverter()
  final ProblemCode code;

  /// An optional human-readable comment describing the problem.
  final String? comment;

  /// Optional arguments for formatting the comment or providing additional context.
  @JsonKey(name: 'args')
  final List<String>? arguments;

  /// Optional contact information for escalation (e.g., email address).
  @JsonKey(name: 'escalate_to')
  final String? escalateTo;

  /// Creates a [ProblemReportBody] with the given [code], [comment], [arguments], and [escalateTo].
  ///
  /// [code] is required. [comment], [arguments], and [escalateTo] are optional.
  ProblemReportBody({
    required this.code,
    this.comment,
    this.arguments,
    this.escalateTo,
  });

  /// Creates a [ProblemReportBody] from a JSON map.
  factory ProblemReportBody.fromJson(Map<String, dynamic> json) =>
      _$ProblemReportBodyFromJson(json);

  /// Converts this [ProblemReportBody] to a JSON map.
  Map<String, dynamic> toJson() => _$ProblemReportBodyToJson(this);
}
