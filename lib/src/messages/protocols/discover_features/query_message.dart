import 'package:json_annotation/json_annotation.dart';
import '../../../../didcomm.dart';
import '../../../annotations/own_json_properties.dart';

part 'query_message.g.dart';
part 'query_message.own_json_props.g.dart';

/// A DIDComm v2 discover features query message.
///
/// This message is used to request information about supported features from another DIDComm agent.
/// It extends [PlainTextMessage] and includes a [QueryBody] containing the list of feature queries.
@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class QueryMessage extends PlainTextMessage {
  /// Constructs a [QueryMessage] with the given [id] and [body].
  ///
  /// The [body] parameter should contain the list of feature queries to be sent.
  QueryMessage({
    required super.id,
    required QueryBody body,
  }) : super(
          type: Uri.parse('https://didcomm.org/discover-features/2.0/queries'),
          body: body.toJson(),
        );

  /// Creates a [QueryMessage] from a JSON map.
  ///
  /// [json] is the JSON map representing the discover features query message.
  factory QueryMessage.fromJson(Map<String, dynamic> json) {
    final message = _$QueryMessageFromJson(json)
      ..assignCustomHeaders(
        json,
        _$ownJsonProperties,
      );

    return message;
  }

  /// Converts this [QueryMessage] to a JSON map, including custom headers.
  ///
  /// Returns a map containing all properties of the message, including any custom headers.
  @override
  Map<String, dynamic> toJson() => withCustomHeaders(
        {
          ...super.toJson(),
          ..._$QueryMessageToJson(this),
        },
      );
}
