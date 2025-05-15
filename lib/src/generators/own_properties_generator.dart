import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import '../annotations/own_properties.dart';

class OwnPropertiesGenerator extends GeneratorForAnnotation<OwnProperties> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    declaration,
    annotation,
    buildStep,
  ) async {
    if (declaration is! ClassElement) {
      print(declaration);
      throw InvalidGenerationSourceError(
        '@OwnProperties can only be used on classes',
        element: declaration,
      );
    }

    final classElement = declaration;
    final className = classElement.name;

    final fields = classElement.fields
        .where((field) => !field.isStatic && !field.isSynthetic)
        .map((field) => "'${field.name}'")
        .join(', ');

    return '''
extension ${className}OwnPropertiesExtension on $className {
  List<String> ownProperties() => [$fields];
}
''';
  }
}
