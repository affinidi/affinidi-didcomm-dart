import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum KeyWrappingAlgorithm {
  ecdhES('ECDH-ES+A256KW'),
  ecdh1PU('ECDH-1PU+A256KW');

  final String value;
  const KeyWrappingAlgorithm(this.value);
}
