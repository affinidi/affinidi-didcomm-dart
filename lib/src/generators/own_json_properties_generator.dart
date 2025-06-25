// ignore_for_file: deprecated_member_use

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
        '@OwnJsonProperties can only be used on classes',
        element: declaration,
      );
    }

    final classElement = declaration;

    final fields = _getAllFieldsIncludingFromParent(classElement)
        .where((field) => !field.isStatic && !field.isSynthetic)
        .map((field) {
      final jsonKey = field.metadata.firstWhereOrNull(
        (meta) => meta.element2?.displayName == 'JsonKey',
      );

      if (jsonKey != null) {
        final name =
            jsonKey.computeConstantValue()?.getField('name')?.toStringValue();

        if (name != null) {
          return "'$name'";
        }
      }

      return "'${field.name}'";
    }).join(', ');

    return '''
  const _\$ownJsonProperties = [$fields];
''';
  }

  List<FieldElement> _getAllFieldsIncludingFromParent(
    ClassElement classElement,
  ) {
    final allFields = <FieldElement>[];
    var current = classElement;

    while (!current.isDartCoreObject) {
      allFields.addAll(
        current.fields.where((field) => !field.isSynthetic && !field.isPrivate),
      );

      current = current.supertype?.element as ClassElement;
    }

    return allFields;
  }
}
