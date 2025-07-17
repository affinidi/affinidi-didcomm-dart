import 'package:json_annotation/json_annotation.dart';

part 'query.g.dart';

@JsonEnum()

/// Enum representing the type of feature in a DIDComm Discover Features query.
@JsonEnum()
enum FeatureType {
  /// A protocol feature type.
  protocol,

  /// A goal-code feature type.
  @JsonValue('goal-code')
  goalCode,

  /// A header feature type.
  header,

  /// Used when an unknown or unrecognized feature type is encountered during deserialization.
  unknown,
}

/// Model for a DIDComm Discover Features query message.
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
