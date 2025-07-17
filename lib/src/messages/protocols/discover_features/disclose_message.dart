import 'package:json_annotation/json_annotation.dart';
import '../../../../didcomm.dart';
import '../../../annotations/own_json_properties.dart';

part 'disclose_message.g.dart';
part 'disclose_message.own_json_props.g.dart';

/// A DIDComm v2 Discover Features disclose message.
///
/// This message is used to disclose supported features in response to a discover features query.
/// It extends [PlainTextMessage] and includes a [DiscloseBody] containing the list of disclosed features.
@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DiscloseMessage extends PlainTextMessage {
  /// Constructs a [DiscloseMessage] with the given [id], [parentThreadId], and [body].
  ///
  /// The [body] parameter should contain the list of disclosed features to be sent.
  DiscloseMessage({
    required super.id,
    required super.parentThreadId,
    required DiscloseBody body,
  }) : super(
          type: Uri.parse('https://didcomm.org/discover-features/2.0/disclose'),
          body: body.toJson(),
        );

  /// Creates a [DiscloseMessage] from a JSON map.
  ///
  /// [json] is the JSON map representing the discover features disclose message.
  factory DiscloseMessage.fromJson(Map<String, dynamic> json) {
    final message = _$DiscloseMessageFromJson(json)
      ..assignCustomHeaders(
        json,
        _$ownJsonProperties,
      );

    return message;
  }

  /// Converts this [DiscloseMessage] to a JSON map, including custom headers.
  ///
  /// Returns a map containing all properties of the message, including any custom headers.
  @override
  Map<String, dynamic> toJson() => withCustomHeaders(
        {
          ...super.toJson(),
          ..._$DiscloseMessageToJson(this),
        },
      );
}
