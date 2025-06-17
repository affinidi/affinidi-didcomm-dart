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

void prettyPrint(String name, Object? object) {
  if (object is String) {
    print('$name: $object\n');
  } else {
    final prettyString = const JsonEncoder.withIndent('  ').convert(object);
    print('$name:\n$prettyString\n${formatBytes(prettyString.length)}\n');
  }
}

String formatBytes(int bytes) {
  final kbs = bytes / 1024;
  return '${kbs.toStringAsFixed(2)}kb';
}

Future<void> writeEnvironmentVariableToFileIfNeed(
  String? environmentVariableName,
  String filePath, {
  bool decodeBase64 = false,
}) async {
  final file = File(filePath);
  final environmentVariable = decodeBase64
      ? utf8.decode(
          base64Decode(Platform.environment[environmentVariableName]!),
        )
      : Platform.environment[environmentVariableName];

  if (environmentVariable == null && !(await file.exists())) {
    throw ArgumentError(
      'Environment variable $environmentVariableName can not be null if file was not created yet',
      'environmentVariableName',
    );
  }

  if (environmentVariable == null) return;
  await file.writeAsString(environmentVariable);
}
