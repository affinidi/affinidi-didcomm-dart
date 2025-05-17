import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum EphemeralKeyType {
  ec('EC'),
  okp('OKP');

  final String value;
  const EphemeralKeyType(this.value);
}
