import 'package:json_annotation/json_annotation.dart';

import '../../didcomm.dart';

/// A [JsonConverter] for serializing and deserializing [ProblemCode] objects to and from strings.
///
/// Converts a [ProblemCode] to its string representation as defined by the DIDComm spec,
/// and parses a string back into a [ProblemCode] instance.
class ProblemCodeConverter implements JsonConverter<ProblemCode, String> {
  /// Creates an instance of [ProblemCodeConverter].
  const ProblemCodeConverter();

  @override

  /// Parses a string into a [ProblemCode] object.
  ///
  /// The string should be in the format: `<sorter>.<scope>.<descriptor1>.<descriptor2>...`.
  /// Returns a [ProblemCode] with [SorterType.unrecognized] or [ScopeType.unrecognized] if the value is not recognized.
  @override
  ProblemCode fromJson(String str) {
    var sorter = SorterType.unrecognized;
    var scope = Scope(
      scope: ScopeType.unrecognized,
    );

    final parts = str.split('.');

    if (parts.isNotEmpty) {
      sorter = SorterType.values.firstWhere(
        (s) => s.code == parts[0],
        orElse: () => SorterType.unrecognized,
      );
    }

    if (parts.length > 1 && parts[1].isNotEmpty) {
      final scopeType = ScopeType.values.firstWhere(
        (s) => s.code == parts[1],
        orElse: () => ScopeType.unrecognized,
      );

      scope = scopeType != ScopeType.unrecognized
          ? Scope(scope: scopeType)
          : Scope(stateName: parts[1]);
    }

    final descriptors = parts.sublist(2);

    return ProblemCode(
      sorter: sorter,
      scope: scope,
      descriptors: descriptors,
    );
  }

  /// Serializes a [ProblemCode] object to its string representation.
  ///
  /// Throws a [StateError] if [SorterType.unrecognized] or [ScopeType.unrecognized] is present,
  /// as these are not intended for serialization.
  @override
  String toJson(ProblemCode object) {
    if (object.sorter == SorterType.unrecognized) {
      throw StateError(
        '${SorterType.unrecognized} is not intended for serialization',
      );
    }

    if (object.scope.scope == ScopeType.unrecognized) {
      throw StateError(
        '${ScopeType.unrecognized} is not intended for serialization',
      );
    }

    return [
      object.sorter.code,
      object.scope.code,
      ...object.descriptors,
    ].join('.');
  }
}
