import 'package:json_annotation/json_annotation.dart';

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
