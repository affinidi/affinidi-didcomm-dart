import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/primitives/asn1_octet_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:ssi/ssi.dart';

Future<Uint8List> extractPrivateKeyBytes(String pemPath) async {
  final pem = await File(pemPath).readAsString();

  final lines = pem.split('\n');
  final base64Str = lines
      .where((line) => !line.startsWith('-----') && line.trim().isNotEmpty)
      .join('');

  final derBytes = base64.decode(base64Str);

  final asn1Parser = ASN1Parser(derBytes);
  final sequence = asn1Parser.nextObject() as ASN1Sequence;

  final privateKeyOctetString = sequence.elements![1] as ASN1OctetString;
  return privateKeyOctetString.valueBytes!;
}

Future<DidDocument> readDidDocument(String didDocumentPath) async {
  final json = await File(didDocumentPath).readAsString();
  return DidDocument.fromJson(jsonDecode(json));
}

Future<String> readDid(String didPath) async {
  return await File(didPath).readAsString();
}
