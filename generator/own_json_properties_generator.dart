// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:didcomm/didcomm.dart';
import 'package:source_gen/source_gen.dart';

/// A code generator for the [OwnJsonProperties] annotation.
///
/// This generator collects all non-static, non-synthetic fields (including inherited fields)
/// from a class annotated with [OwnJsonProperties] and generates a constant list of property names when they are serialized to JSON.
class OwnJsonPropertiesGenerator
    extends GeneratorForAnnotation<OwnJsonProperties> {
  /// Generates a constant list of JSON property names for the annotated class.
  ///
  /// [declaration]: The element being annotated (should be a [ClassElement]).
  /// [annotation]: The annotation instance.
  /// [buildStep]: The current build step.
  ///
  /// Throws [InvalidGenerationSourceError] if the annotation is not used on a class.
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element declaration,
    ConstantReader annotation,
    BuildStep buildStep,
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
