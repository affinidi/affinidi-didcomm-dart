# Affinidi DIDComm for Dart

A Dart package for implementing secure and private communication on your app using DIDComm v2 Messaging protocol. DIDComm v2 Messaging is a decentralised communication protocol that uses a Decentralised Identifier (DID) to establish a secure communication channel and send a private and verifiable message.

The DIDComm for Dart package provides the tools and libraries to enable your app to send DIDComm messages. It supports various encryption algorithms and DID methods, such as `did:peer`, `did:key`, and `did:web` for signing and encrypting to ensure the secure and private transport of messages to the intended recipient, establishing verifiable and trusted communication.


## Table of Contents

  - [Core Concepts](#core-concepts)
  - [Key Features](#key-features)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Support & feedback](#support--feedback)
  - [Contributing](#contributing)


## Core Concepts

The DIDComm for Dart package utilises existing open standards and cryptographic techniques to provide secure, private, and verifiable communication.

- **Decentralised Identifier (DID)** - A globally unique identifier that enables secure interactions. The DID is the cornerstone of Self-Sovereign Identity (SSI), a concept that aims to put individuals or entities in control of their digital identities.

- **DID Document** - A DID is a URI (Uniform Resource Identifier) that resolves into a DID Document that contains information such as cryptographic public keys, authentication methods, and service endpoints. It allows others to verify signatures, authenticate interactions, and validate messages cryptographically.

- **DIDComm Message** - is a JSON Web Message (JWM), a lightweight, secure, and standardised format for structured communication using JSON. It represents headers, message types, routing metadata, and payloads designed to enable secure and interoperable communication across different systems.

- **Mediator** - A service that handles and routes messages sent between participants (e.g., users, organisations, another mediator, or even AI agents).

- **Wallet** - A digital wallet to manage cryptographic keys supporting different algorithms for signing and verifying messages.

## Key Features

- Implements the DIDComm Message v2.0 protocol.

- Support for multiple DID methods like `did:peer` and `did:web` to prove control of user's digital identity.

- Support for digital wallets under [Affinidi Dart SSI](https://pub.dev/packages/ssi) to manage cryptographic keys.

- Support key types like `P256`, `ED25519` and `SECP256K1` to encrypt and sign messages.

- Connect and authenticate with different mediator services that follow the DIDComm Message v2.0 protocol.

## Requirements

- Dart SDK version ^3.6.0

## Installation

Run:

```bash
dart pub add didcomm
```

or manually, add the package into your `pubspec.yaml` file:

```yaml
dependencies:
  didcomm: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

Visit the pub.dev install page of the Dart package for more information.

## Usage

After successfully installing the package, import it into your code.

```dart
import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:didcomm/src/jwks/jwks.dart';
import 'package:didcomm/src/messages/algorithm_types/encryption_algorithm.dart';
import 'package:didcomm/src/messages/didcomm_message.dart';
import 'package:ssi/ssi.dart';

void main() async {
  final aliceKeyStore = InMemoryKeyStore();
  final aliceWallet = PersistentWallet(aliceKeyStore);

  final bobKeyStore = InMemoryKeyStore();
  final bobWallet = PersistentWallet(bobKeyStore);

  final aliceKeyId = 'alice-key-1';
  final aliceKeyPair = await aliceWallet.generateKey(
      keyId: aliceKeyId,
      keyType: KeyType.p256,
  );

  final aliceDidDocument = DidKey.generateDocument(aliceKeyPair.publicKey);

  final aliceSigner = DidSigner(
      didDocument: aliceDidDocument,
      keyPair: aliceKeyPair,
      didKeyId: aliceDidDocument.verificationMethod[0].id,
      signatureScheme: SignatureScheme.ecdsa_p256_sha256,
  );

  final bobKeyId = 'bob-key-1';
  final bobKeyPair = await bobWallet.generateKey(
      keyId: bobKeyId,
      keyType: KeyType.p256,
  );

  final bobDidDocument = DidKey.generateDocument(bobKeyPair.publicKey);

  final plainTextMassage = PlainTextMessage(
      id: '041b47d4-9c8f-4a24-ae85-b60ec91b025c',
      from: aliceDidDocument.id,
      to: [bobDidDocument.id],
      type: Uri.parse('https://didcomm.org/example/1.0/message'),
      body: {'content': 'Hello, Bob!'},
  );

  print(jsonEncode(plainTextMassage));
  print('');

  final signedMessageByAlice = await SignedMessage.pack(
      plainTextMassage,
      signer: aliceSigner,
  );

  print(jsonEncode(signedMessageByAlice));
  print('');
}
```

For more sample usage, go to the [example folder](https://github.com/affinidi/didcomm-dart/tree/main/example).

## Support & feedback

If you face any issues or have suggestions, please don't hesitate to contact us using [this link](https://share.hsforms.com/1i-4HKZRXSsmENzXtPdIG4g8oa2v).

### Reporting technical issues

If you have a technical issue with the Affinidi SSI's codebase, you can also create an issue directly in GitHub.

1. Ensure the bug was not already reported by searching on GitHub under
   [Issues](https://github.com/affinidi/didcomm-dart/issues).

2. If you're unable to find an open issue addressing the problem,
   [open a new one](https://github.com/affinidi/didcomm-dart/issues/new).
   Be sure to include a **title and clear description**, as much relevant information as possible,
   and a **code sample** or an **executable test case** demonstrating the expected behaviour that is not occurring.

## Contributing

Want to contribute?

Head over to our [CONTRIBUTING](https://github.com/affinidi/didcomm-dart/blob/main/CONTRIBUTING.md) guidelines.
