// ignore_for_file: depend_on_referenced_packages

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/generators/own_json_properties_generator.dart';

/// Creates a [PartBuilder] for generating custom JSON property lists using [OwnJsonPropertiesGenerator].
///
/// [options]: The builder options provided by the build system.
/// Returns a [PartBuilder] configured to generate '.own_json_props.g.dart' files.
Builder ownJsonPropertiesBuilder(BuilderOptions options) =>
    PartBuilder([OwnJsonPropertiesGenerator()], '.own_json_props.g.dart');
