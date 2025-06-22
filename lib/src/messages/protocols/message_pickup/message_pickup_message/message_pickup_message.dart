import 'package:json_annotation/json_annotation.dart';

import '../../../../annotations/own_json_properties.dart';
import '../../../../converters/epoch_seconds_converter.dart';
import '../../../core.dart';

part 'message_pickup_message.g.dart';
part 'message_pickup_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MessagePickupMessage extends PlainTextMessage {
  @JsonKey(name: 'return_route')
  final String returnRoute;

  MessagePickupMessage({
    required super.id,
    required super.to,
    required super.from,
    required super.type,
    required super.body,
    super.expiresTime,
    this.returnRoute = 'all',
  });

  factory MessagePickupMessage.fromJson(Map<String, dynamic> json) {
    final message = _$MessagePickupMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  @override
  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$MessagePickupMessageToJson(this));
}
