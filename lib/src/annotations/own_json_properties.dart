/// Annotation to mark a class for custom JSON property collection.
///
/// When applied, this annotation enables code generation to collect all non-static,
/// non-synthetic fields (including inherited fields) for use in custom serialization logic.
class OwnJsonProperties {
  /// Creates an [OwnJsonProperties] annotation.
  const OwnJsonProperties();
}
