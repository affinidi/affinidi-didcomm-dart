import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum EncryptionAlgorithm {
  a256cbc('A256CBC-HS512'),
  a256gcm('A256GCM');

  final String value;
  const EncryptionAlgorithm(this.value);
}
