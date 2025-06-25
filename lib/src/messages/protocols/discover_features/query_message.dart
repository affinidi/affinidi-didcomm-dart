import 'package:json_annotation/json_annotation.dart';
import '../../didcomm_message.dart';

part 'query_message.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class QueryMessage extends DidcommMessage {
  QueryMessage();

  factory QueryMessage.fromJson(Map<String, dynamic> json) =>
      _$QueryMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$QueryMessageToJson(this);
}
