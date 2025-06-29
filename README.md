# Affinidi DIDComm for Dart

A Dart package for implementing secure and private communication on your app using DIDComm v2 Messaging protocol. DIDComm v2 Messaging is a decentralized communication protocol that uses a Decentralized Identifier (DID) to establish a secure communication channel and send a private and verifiable message.

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

The DIDComm for Dart package utilizes existing open standards and cryptographic techniques to provide secure, private, and verifiable communication.

- **Decentralized Identifier (DID)** - A globally unique identifier that enables secure interactions. The DID is the cornerstone of Self-Sovereign Identity (SSI), a concept that aims to put individuals or entities in control of their digital identities.

- **DID Document** - A DID is a URI (Uniform Resource Identifier) that resolves into a DID Document that contains information such as cryptographic public keys, authentication methods, and service endpoints. It allows others to verify signatures, authenticate interactions, and validate messages cryptographically.

- **DIDComm Message** - is a JSON Web Message (JWM), a lightweight, secure, and standardized format for structured communication using JSON. It represents headers, message types, routing metadata, and payloads designed to enable secure and interoperable communication across different systems.

- **Mediator** - A service that handles and routes messages sent between participants (e.g., users, organizations, another mediator, or even AI agents).

- **Wallet** - A digital wallet to manage cryptographic keys supporting different algorithms for signing and verifying messages.

### DIDComm Message Envelopes

DIDComm v2 messages can be sent in three main forms: plaintext, signed, and encrypted. Each form (called "envelope") provides different security and privacy guarantees, and can be combined in various ways.

- **Plaintext message**: A message that is neither signed nor encrypted. It is readable by anyone and provides no integrity or authenticity guarantees. Used for non-sensitive data, debugging, or as the inner content of other envelopes.
- **Signed message**: A message that is digitally signed but not encrypted. Anyone can read it, but the recipient can prove who signed it (non-repudiation). Used when the origin of the message must be provable to third parties.
- **Encrypted message**: A message that is encrypted for one or more recipients. Only intended recipients can read it. Encryption can be:
  - **Authenticated encryption (authcrypt, ECDH-1PU)**: Proves the sender's identity to the recipient (but not to intermediaries). Used when both confidentiality and sender authenticity are required.
  - **Anonymous encryption (anoncrypt, ECDH-ES)**: Hides the sender's identity from the recipient and intermediaries. Used when sender anonymity is required.

**ECDH-1PU** is used for authenticated encryption (authcrypt), where the sender's key is involved in the encryption process, allowing the recipient to verify the sender's identity. **ECDH-ES** is used for anonymous encryption (anoncrypt), where only the recipient's key is used, and the sender remains anonymous.

Those tree envelops above can be combined in the following ways:

- **plaintext**:  
  - **Purpose**: Used as the building block of higher-level protocols, but rarely transmitted directly, since it lacks security guarantees.
  - **Use case**: Public announcements, non-confidential data, debugging, or as the inner content of other envelopes.

- **signed(plaintext)**:  
  - **Purpose**: Adds non-repudiation to a plaintext message; whoever receives a message wrapped in this way can prove its origin to any external party.
  - **Use case**: Audit trails, legal or regulatory messages, or when recipients need to prove message origin to third parties.

- **anoncrypt(plaintext)**:  
  - **Purpose**: Guarantees confidentiality and integrity without revealing the identity of the sender.
  - **Use case**: Anonymous tips, whistleblowing, or when sender identity must be hidden.

- **authcrypt(plaintext)**:  
  - **Purpose**: Guarantees confidentiality and integrity. Also proves the identity of the sender – but in a way that only the recipient can verify. This is the default wrapping choice, and SHOULD be used unless a different goal is clearly identified.
  - **Use case**: Most secure communications where both privacy and sender authenticity are required.

- **anoncrypt(sign(plaintext))**:  
  - **Purpose**: Guarantees confidentiality, integrity, and non-repudiation – but prevents an observer of the outer envelope from accessing the signature. Relative to authcrypt(plaintext), this increases guarantees to the recipient, since non-repudiation is stronger than simple authentication. However, it also forces the sender to talk “on the record” and is thus not assumed to be desirable by default.
  - **Use case**: Sensitive communications where sender wants to prove authorship to recipient, but remain anonymous to intermediaries.

- **authcrypt(sign(plaintext))**:  
  - **Purpose**: Adds no useful guarantees over the previous choice, and is slightly more expensive, so this wrapping combination SHOULD NOT be emitted by conforming implementations. However, implementations MAY accept it. If they choose to do so, they MUST emit an error if the signer of the plaintext is different from the sender identified by the authcrypt layer.
  - **Use case**: Rarely used; only for compatibility or special cases.

- **anoncrypt(authcrypt(plaintext))**:  
  - **Purpose**: A specialized combination that hides the sender key ID (skid) header in the authcrypt envelope, so the hop immediately sourceward of a mediator cannot discover an identifier for the sender.
  - **Use case**: Advanced scenarios requiring layered security and sender anonymity from intermediaries.

Here is a comparison:

| Envelope Type                      | Confidentiality | Sender Authenticity | Non-repudiation | Sender Anonymity |
|------------------------------------|-----------------|---------------------|-----------------|------------------|
| plaintext (no envelope)            | ❌              | ❌                  | ❌              | ❌               |
| signed(plaintext)                  | ❌              | ✅                  | ✅              | ❌               |
| anoncrypt(plaintext)               | ✅              | ❌                  | ❌              | ✅               |
| authcrypt(plaintext)               | ✅              | ✅                  | ❌              | ❌               |
| anoncrypt(sign(plaintext))         | ✅              | ✅                  | ✅              | ✅               |
| authcrypt(sign(plaintext))         | ✅              | ✅                  | ✅              | ❌               |
| anoncrypt(authcrypt(plaintext))    | ✅              | ✅                  | ❌              | ✅               |

**Summary:**  
- Use **plaintext** for non-sensitive data.
- Use **signed(plaintext)** for integrity and non-repudiation.
- Use **anoncrypt(plaintext)** for confidential, sender-anonymous messages.
- Use **authcrypt(plaintext)** for confidential, authenticated messages.
- Use **anoncrypt(sign(plaintext))** for confidential, non-repudiable, sender-anonymous messages.
- Use **authcrypt(sign(plaintext))** for the highest level of security and auditability (rarely needed).
- Use **anoncrypt(authcrypt(plaintext))** for advanced layered security and sender anonymity from intermediaries.

For more details, see the [DIDComm Messaging specification](https://identity.foundation/didcomm-messaging/spec/#iana-media-types).

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

Below is a step-by-step example of secure communication between Alice and Bob using the DIDComm Dart package. This demonstrates how to construct, sign, encrypt, and unpack messages according to the [DIDComm Messaging spec](https://identity.foundation/didcomm-messaging/spec).

### 1. Setup: Wallets and DIDs

```dart
final aliceKeyStore = InMemoryKeyStore();
final aliceWallet = PersistentWallet(aliceKeyStore);
final bobKeyStore = InMemoryKeyStore();
final bobWallet = PersistentWallet(bobKeyStore);

// Generate key pairs for Alice and Bob
final aliceKeyPair = await aliceWallet.generateKey(keyId: 'alice-key-1', keyType: KeyType.p256);
final bobKeyPair = await bobWallet.generateKey(keyId: 'bob-key-1', keyType: KeyType.p256);

// Create DID Documents
final aliceDidDocument = DidKey.generateDocument(aliceKeyPair.publicKey);
final bobDidDocument = DidKey.generateDocument(bobKeyPair.publicKey);
```

### 2. Construct a Plain Text Message

A plain text message is a simple JSON message with headers and a body.

```dart
final plainTextMessage = PlainTextMessage(
  id: '041b47d4-9c8f-4a24-ae85-b60ec91b025c', // Unique message ID
  from: aliceDidDocument.id,                   // Sender's DID
  to: [bobDidDocument.id],                     // Recipient's DID(s)
  type: Uri.parse('https://didcomm.org/example/1.0/message'), // Message type URI
  body: {'content': 'Hello, Bob!'},            // Message payload
);
plainTextMessage['custom-header'] = 'custom-value'; // Add custom headers if needed
```

### 3. Sign the Message (Optional)

Signing a message is optional in DIDComm. It is required when you need to provide non-repudiation—proof that the sender cannot deny authorship of the message. This is important for scenarios where:
- The recipient must be able to prove to a third party that the sender authored the message (e.g., legal, regulatory, or audit requirements).
- The message may be forwarded or relayed, and recipients need to verify its origin independently of the transport channel.
- You want to ensure message integrity and origin even if the message is not encrypted.

```dart
final aliceSigner = DidSigner(
  didDocument: aliceDidDocument,
  keyPair: aliceKeyPair,
  didKeyId: aliceDidDocument.verificationMethod[0].id,
  signatureScheme: SignatureScheme.ecdsa_p256_sha256,
);

final signedMessage = await SignedMessage.pack(
  plainTextMessage,
  signer: aliceSigner, // The signer instance
);
```
- `signer`: The `DidSigner` instance containing Alice's DID, key pair, and signature scheme.

### 4. Encrypt the Message (Optional but Recommended)

Encryption is optional in DIDComm, but highly recommended to protect the confidentiality of your messages. Encryption is needed when:
- You want to ensure that only the intended recipient(s) can read the message content.
- You need to protect sensitive data from being exposed to intermediaries or eavesdroppers.
- You want to provide authenticity (via authenticated encryption) so the recipient knows the message came from someone with the sender's key.

To ensure confidentiality and authenticity, Alice encrypts the signed or plain text message for Bob using authenticated encryption:

- **Confidentiality** means only Bob can read the message content.
- **Authenticity (via authenticated encryption)** means Bob can verify the message was encrypted by someone with Alice's key, but this does not provide non-repudiation (Alice could deny sending it).
- **Sender identity privacy:** With authcrypt, only the intended recipient (Bob) can see the sender's identity. Any intermediaries or eavesdroppers cannot determine who sent the message, as the sender's identity is encrypted and protected during transport.

```dart
final encryptedMessage = await EncryptedMessage.packWithAuthentication(
  message, // The signed or plain text message to encrypt
  keyPair: aliceKeyPair, // Alice's key pair for encryption
  didKeyId: aliceDidDocument.keyAgreement[0].id, // Alice's key agreement key ID
  recipientDidDocuments: [bobDidDocument], // List of recipient DID Documents
  encryptionAlgorithm: EncryptionAlgorithm.a256cbc, // Encryption algorithm
);
```
- `keyPair`: Alice's key pair used for authenticated encryption.
- `didKeyId`: The key ID from Alice's DID Document for key agreement.
- `recipientDidDocuments`: The recipient's DID Document(s).
- `encryptionAlgorithm`: The encryption algorithm to use (e.g., `a256cbc`).

#### Example: Anonymous Encryption (packAnonymously)

If you want to encrypt a message without revealing the sender's identity (anoncrypt), use `packAnonymously`:

```dart
final anonymousEncryptedMessage = await EncryptedMessage.packAnonymously(
  message, // The signed or plain text message to encrypt
  recipientDidDocuments: [bobDidDocument], // List of recipient DID Documents
  encryptionAlgorithm: EncryptionAlgorithm.a256cbc, // Encryption algorithm
);
```
- `message`: The message to encrypt (can be plain or signed).
- `recipientDidDocuments`: The recipient's DID Document(s).
- `encryptionAlgorithm`: The encryption algorithm to use.

In this case, Bob can decrypt and read the message, but cannot determine who sent it. This is useful for scenarios where sender anonymity is required.

#### High-level Packing Helpers

The `DidcommMessage` class also provides high-level helper methods for common packing workflows:

- **packIntoEncryptedMessage**: Packs a plain text message into an encrypted message using the provided cryptographic parameters. Use this when you want to send a confidential message and do not require non-repudiation. Accepts options for sender key pair, key ID, key type, recipient DID Documents, key wrapping algorithm, and encryption algorithm.

- **packIntoSignedMessage**: Packs a plain text message into a signed message. Use this when you want to provide non-repudiation and message integrity, but do not require confidentiality (encryption).

#### Unpacking
Bob receives the encrypted message and unpacks it:

```dart
final unpackedMessage = await DidcommMessage.unpackToPlainTextMessage(
  message: jsonDecode(sentMessageByAlice) as Map<String, dynamic>, // The received message
  recipientWallet: bobWallet, // Bob's wallet for decryption
  expectedMessageWrappingTypes: [MessageWrappingType.authcryptPlaintext], // Expected wrapping
  expectedSigners: [aliceSigner.didKeyId], // List of expected signers' key IDs
);
```
- `message`: The received message as a decoded JSON map.
- `recipientWallet`: The wallet instance used to decrypt the message.
- `expectedMessageWrappingTypes`: List of expected message wrapping types. This argument ensures that the unpacked message matches the expected security and privacy guarantees (e.g., plaintext, signed, or encrypted). The values are from the `MessageWrappingType` enum, which maps to the [DIDComm IANA media types](https://identity.foundation/didcomm-messaging/spec/#iana-media-types), such as `authcryptPlaintext` for authenticated encryption, `signedPlaintext` for signed messages, and `plaintext` for unprotected messages. This helps prevent downgrade attacks and ensures the message is processed as intended.
- `expectedSigners`: List of key IDs whose signatures are expected and will be verified.

### 6. Full Example

See [`example/didcomm_example.dart`](https://github.com/affinidi/didcomm-dart/blob/main/example/didcomm_example.dart) for a complete runnable example.

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
