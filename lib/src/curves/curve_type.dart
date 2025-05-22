import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum CurveType {
  p256('P-256'),
  p384('P-384'),
  p521('P-521'),
  secp256k1('secp256k1'),
  x25519('X25519');

  final String value;
  const CurveType(this.value);

  bool isSecp256OrPCurve() {
    return value.startsWith('P') || value.startsWith('secp256k');
  }

  bool isXCurve() {
    return value.startsWith('X');
  }
}
