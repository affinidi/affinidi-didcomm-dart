import 'package:json_annotation/json_annotation.dart';
import '../../../../didcomm.dart';

part 'disclose_body.g.dart';

/// Model for the body of a DIDComm Discover Features disclose message.
///
/// Contains a list of [Disclosure] objects that describe the features being disclosed.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DiscloseBody {
  /// The list of disclosed features.
  final List<Disclosure> disclosures;

  /// Constructs a [DiscloseBody] instance with the given [disclosures].
  DiscloseBody({
    required this.disclosures,
  });

  /// Creates a [DiscloseBody] from a JSON map.
  factory DiscloseBody.fromJson(Map<String, dynamic> json) =>
      _$DiscloseBodyFromJson(json);

  /// Converts this [DiscloseBody] to a JSON map.
  Map<String, dynamic> toJson() => _$DiscloseBodyToJson(this);
}
