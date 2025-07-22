// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/primitives/asn1_octet_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:ssi/ssi.dart';

/// Extracts pem into bytes.
///
/// [pemPath]: path to pem file
/// Returns pem as bytes.
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

/// Reads DID document.
///
/// [didDocumentPath]: a path to DID document.
/// Returns the DID document.
Future<DidDocument> readDidDocument(String didDocumentPath) async {
  final json = await File(didDocumentPath).readAsString();
  return DidDocument.fromJson(jsonDecode(json));
}

/// Reads DID from a file.
///
/// [didPath]: a path to DID file.
/// Returns the DID.
Future<String> readDid(String didPath) async {
  return await File(didPath).readAsString();
}

/// Pretty prints the object prefixed with its name.
///
/// [name]: The bytes to encode.
/// [object]: The bytes to encode.
void prettyPrint(
  String name, {
  Object? object,
}) {
  if (object == null) {
    print(name);
  } else if (object is String) {
    print('$name: $object\n');
  } else {
    final prettyString = const JsonEncoder.withIndent('  ').convert(object);
    print('$name:\n$prettyString\n${formatBytes(prettyString.length)}\n');
  }
}

/// Converts bytes int human readable version.
///
/// [bytes]: bytes to convert.
/// Returns human readable version for bytes.
String formatBytes(int bytes) {
  final units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  final i = bytes == 0 ? 0 : (log(bytes) / log(1024)).floor();
  final size =
      (bytes / pow(1024, i)).toStringAsFixed(2).replaceFirst('.00', '');

  final unit = units[i];
  return '$size$unit';
}

/// Writes environment variable into file, if it was not written there already.
///
/// [environmentVariableName]:
/// [filePath]:
/// [decodeBase64]:
Future<void> writeEnvironmentVariableToFileIfNeed(
  String? environmentVariableName,
  String filePath, {
  bool decodeBase64 = false,
}) async {
  final file = File(filePath);
  final environmentVariable = Platform.environment[environmentVariableName];

  if ((environmentVariable == null || environmentVariable.isEmpty) &&
      !(await file.exists())) {
    throw ArgumentError(
      'Environment variable $environmentVariableName can not be null if file was not created yet',
      'environmentVariableName',
    );
  }

  if (environmentVariable == null) return;

  if (decodeBase64) {
    final bytes = base64Decode(environmentVariable);
    await file.writeAsString(ascii.decode(bytes));
  } else {
    await file.writeAsString(environmentVariable);
  }
}
