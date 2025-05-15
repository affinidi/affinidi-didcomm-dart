import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/generators/own_json_properties_generator.dart';

Builder ownJsonPropertiesBuilder(BuilderOptions options) =>
    PartBuilder([OwnJsonPropertiesGenerator()], '.own_json_props.g.dart');
