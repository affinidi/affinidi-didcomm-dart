import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:collection/collection.dart';
import '../annotations/own_json_properties.dart';

class OwnJsonPropertiesGenerator
    extends GeneratorForAnnotation<OwnJsonProperties> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    declaration,
    annotation,
    buildStep,
  ) async {
    if (declaration is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@OwnProperties can only be used on classes',
        element: declaration,
      );
    }

    final classElement = declaration;
    final className = classElement.name;

    final fields = classElement.fields
        .where((field) => !field.isStatic && !field.isSynthetic)
        .map((field) {
          final jsonKey = field.metadata.firstWhereOrNull(
            (meta) => meta.element2?.displayName == 'JsonKey',
          );

          if (jsonKey != null) {
            final name =
                jsonKey
                    .computeConstantValue()
                    ?.getField('name')
                    ?.toStringValue();

            if (name != null) {
              return "'$name'";
            }
          }

          return "'${field.name}'";
        })
        .join(', ');

    return '''
extension ${className}OwnPropertiesExtension on $className {
  List<String> ownProperties() => [$fields];
}
''';
  }
}
