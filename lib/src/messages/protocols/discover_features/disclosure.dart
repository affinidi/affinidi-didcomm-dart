import 'package:json_annotation/json_annotation.dart';

part 'disclosure.g.dart';

/// Model for a DIDComm discover features disclosure.
///
/// Contains information about a single feature that is disclosed in response to a query.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Disclosure {
  /// The type of feature being disclosed.
  @JsonKey(name: 'feature-type')
  final String featureType;

  /// The unique identifier of the disclosed feature.
  final String id;

  /// The roles supported for this feature, if any.
  final List<String>? roles;

  /// Constructs a [Disclosure] instance.
  Disclosure({
    required this.id,
    required this.featureType,
    this.roles,
  });

  /// Creates a [Disclosure] from a JSON map.
  factory Disclosure.fromJson(Map<String, dynamic> json) =>
      _$DisclosureFromJson(json);

  /// Converts this [Disclosure] to a JSON map.
  Map<String, dynamic> toJson() => _$DisclosureToJson(this);
}
