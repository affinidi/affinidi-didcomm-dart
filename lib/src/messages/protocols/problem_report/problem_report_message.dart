import 'package:json_annotation/json_annotation.dart';
import '../../../../didcomm.dart';
import '../../../annotations/own_json_properties.dart';

part 'problem_report_message.g.dart';
part 'problem_report_message.own_json_props.g.dart';

/// A DIDComm problem report message, as defined by the DIDComm Messaging specification.
///
/// This message is used to communicate errors or problems encountered during protocol interactions.
@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ProblemReportMessage extends PlainTextMessage {
  /// Creates a [ProblemReportMessage] with the given [id], [parentThreadId], optional [acknowledged], and [body].
  ///
  /// The [body] parameter is a [ProblemReportBody] containing the problem details.
  ProblemReportMessage({
    required super.id,
    required super.parentThreadId,
    super.acknowledged,
    required ProblemReportBody body,
  }) : super(
          type: Uri.parse(
            'https://didcomm.org/report-problem/2.0/problem-report',
          ),
          body: body.toJson(),
        );

  /// Creates a [ProblemReportMessage] from a JSON map.
  ///
  /// [json] is the JSON map representing the problem report message.
  factory ProblemReportMessage.fromJson(Map<String, dynamic> json) {
    final message = _$ProblemReportMessageFromJson(json)
      ..assignCustomHeaders(
        json,
        _$ownJsonProperties,
      );
    return message;
  }

  /// Converts this [ProblemReportMessage] to a JSON map, including custom headers.
  @override
  Map<String, dynamic> toJson() => withCustomHeaders(
        {
          ...super.toJson(),
          ..._$ProblemReportMessageToJson(this),
        },
      );
}
