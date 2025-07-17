import 'package:json_annotation/json_annotation.dart';

import '../../../../didcomm.dart';

part 'query_body.g.dart';

/// Model for the body of a DIDComm Discover Features query message.
///
/// Contains a list of [Query] objects to be executed as part of the discover features protocol.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class QueryBody {
  /// The list of queries to be executed in the discover features protocol.
  final List<Query> queries;

  /// Creates a new instance of [QueryBody] with the given [queries].
  QueryBody({required this.queries});

  /// Converts the [QueryBody] instance to a JSON map.
  Map<String, dynamic> toJson() => _$QueryBodyToJson(this);

  /// Creates a [QueryBody] instance from a JSON map.
  factory QueryBody.fromJson(Map<String, dynamic> json) =>
      _$QueryBodyFromJson(json);
}
