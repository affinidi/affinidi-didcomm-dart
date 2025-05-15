import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import './src/generators/own_properties_generator.dart';

Builder ownPropertiesBuilder(BuilderOptions options) =>
    PartBuilder([OwnPropertiesGenerator()], '.own_props.g.dart');
