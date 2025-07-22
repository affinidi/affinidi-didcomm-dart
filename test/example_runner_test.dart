import 'dart:io';
import 'package:didcomm/didcomm.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() async {
  // Run commands below in your terminal to generate keys for Alice and Bob:
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/alice_private_key.pem
  // openssl ecparam -name prime256v1 -genkey -noout -out example/keys/bob_private_key.pem
  // OR
  // set environment variables TEST_MEDIATOR_DID, TEST_ALICE_PRIVATE_KEY_PEM, and TEST_BOB_PRIVATE_KEY_PEM

  // Create and run a DIDComm mediator, for instance with https://portal.affinidi.com.
  // Copy its DID Document URL into example/mediator/mediator_did.txt.

  const mediatorDidPath = './example/mediator/mediator_did.txt';
  const alicePrivateKeyPath = './example/keys/alice_private_key.pem';
  const bobPrivateKeyPath = './example/keys/bob_private_key.pem';

  await writeEnvironmentVariableToFileIfNeed(
    'TEST_MEDIATOR_DID',
    mediatorDidPath,
  );

  await writeEnvironmentVariableToFileIfNeed(
    'TEST_ALICE_PRIVATE_KEY_PEM',
    alicePrivateKeyPath,
    decodeBase64: true,
  );

  await writeEnvironmentVariableToFileIfNeed(
    'TEST_BOB_PRIVATE_KEY_PEM',
    bobPrivateKeyPath,
    decodeBase64: true,
  );

  test(
    'Running example files to check if they are aligned with the code',
    () async {
      final exampleDirectory = Directory(
        join(
          Directory.current.path,
          'example',
        ),
      );

      if (!await exampleDirectory.exists()) {
        failTest('No example directory found.');
      }

      final dartFiles = exampleDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      if (dartFiles.isEmpty) {
        failTest('No Dart example files found.');
      }

      final filesWithMain = <File>[];

      for (final file in dartFiles) {
        final content = await file.readAsString();
        if (content.contains('void main()')) {
          filesWithMain.add(file);
        }
      }

      if (filesWithMain.isEmpty) {
        failTest('No Dart example files with void main() found.');
        return;
      }

      final errors = <String>[];

      await Future.wait(filesWithMain.map((file) async {
        final result = await Process.run(
          Platform.resolvedExecutable,
          [file.path],
          runInShell: true,
        );

        if (result.exitCode != 0) {
          errors.add(
            'FAILED: ${file.path}.\nExit code: ${result.exitCode}.\nStdout: ${result.stdout}.\nStderr: ${result.stderr}.',
          );
        }
      }));

      if (errors.isNotEmpty) {
        failTest(errors.join('\n'));
      }

      expect(errors, isEmpty);
    },
    // gives enough time for the examples to run
    timeout: const Timeout.factor(2),
  );
}

void failTest(String message) {
  throw Exception(message);
}
