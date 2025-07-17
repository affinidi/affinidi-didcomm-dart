import 'package:json_annotation/json_annotation.dart';

import 'feature_type.dart';

part 'query.g.dart';

/// Model for a DIDComm discover features query.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Query {
  /// The type of feature being queried.
  @JsonKey(name: 'feature-type', unknownEnumValue: FeatureType.unknown)
  final FeatureType featureType;

  /// The match pattern for the feature query (e.g., protocol URI or wildcard).
  final String match;

  /// Constructs a [Query] instance.
  Query({
    required this.featureType,
    required this.match,
  });

  /// Creates a [Query] from a JSON map.
  factory Query.fromJson(Map<String, dynamic> json) => _$QueryFromJson(json);

  /// Converts this [Query] to a JSON map.
  Map<String, dynamic> toJson() => _$QueryToJson(this);
}
