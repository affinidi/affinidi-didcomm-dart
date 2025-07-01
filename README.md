# Affinidi DIDComm for Dart

A Dart package for implementing secure and private communication on your app using DIDComm v2 Messaging protocol. DIDComm v2 Messaging is a decentralised communication protocol that uses a Decentralised Identifier (DID) to establish a secure communication channel and send a private and verifiable message.

The DIDComm for Dart package provides the tools and libraries to enable your app to send DIDComm messages. It supports various encryption algorithms and DID methods, such as `did:peer`, `did:key`, and `did:web` for signing and encrypting to ensure the secure and private transport of messages to the intended recipient, establishing verifiable and trusted communication.


## Table of Contents

  - [Core Concepts](#core-concepts)
  - [Key Features](#key-features)
  - [DIDComm Message Envelopes](#didcomm-message-envelopes)
    - [Combining Different Envelope Types](#combining-different-envelope-types)
    - [Benefits of Combining Envelope Types](#benefits-of-combining-envelope-types)
    - [Envelope Types Summary](#envelope-types-summary)
  - [Ed25519/X25519 Curve Conversion](#ed25519x25519-curve-conversion)
  - [Key Type Selection for Authcrypt and Anoncrypt](#key-type-selection-for-authcrypt-and-anoncrypt)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
    - [1. Set up Wallets and DIDs](#1-set-up-wallets-and-dids)
    - [2. Compose a Plain Text Message](#2-compose-a-plain-text-message)
    - [3. Sign the Message](#3-sign-the-message)
    - [4. Encrypt the Message](#4-encrypt-the-message)
    - [More Examples](#more-examples)
  - [Pack and Unpack DIDComm Message Helpers](#pack-and-unpack-didcomm-message-helpers)
    - [packIntoEncryptedMessage](#packintoencryptedmessage)
    - [packIntoSignedMessage](#packintosignedmessage)
    - [packIntoSignedAndEncryptedMessages](#packintosignedandencryptedmessages)
    - [unpackToPlainTextMessage](#unpacktoplaintextmessage)
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

- Support for DIDComm Messaging Envelope types.

- Connect and authenticate with different mediator services that follow the DIDComm Message v2.0 protocol.

## DIDComm Message Envelopes

DIDComm v2 messages can be sent in the following formats: plaintext, signed, and encrypted. Each format, called "envelope", provides different security and privacy guarantees and can be combined in various ways.

- **Plaintext message**: A message that is neither signed nor encrypted. It is readable by anyone and provides no integrity or authenticity guarantees. Used for non-sensitive data, debugging, or as the inner content of other envelopes.
- **Signed message**: A message that is digitally signed but not encrypted. Anyone can read it, but the recipient can prove who signed it (non-repudiation)—used when the message's origin must be provable to the recipient or third parties.
- **Encrypted message**: An encrypted message for one or more recipients. Only the intended recipients can read the content of the message. Encryption can be:

  - **Authenticated encryption (authcrypt, ECDH-1PU)**: Proves the sender's identity to the recipient (but not to intermediaries). Used when both confidentiality and sender authenticity are required.

    It uses the **ECDH-1PU** for authenticated encryption (authcrypt), where the sender's key is involved in the encryption process, allowing the recipient to verify the sender's identity.

  - **Anonymous encryption (anoncrypt, ECDH-ES)**: Hides the sender's identity from the recipient and intermediaries. It is used when the sender's anonymity is required.

    It uses **ECDH-ES** for anonymous encryption (anoncrypt), where only the recipient's key is used, and the sender remains anonymous.

### Combining Different Envelope Types

You can combine the DIDComm Message Envelope types in the following ways:

- **plaintext**:  
  - **Purpose**: Used as the building block of higher-level protocols, but rarely transmitted directly, since it lacks security guarantees.
  - **Use case**: Public announcements, non-confidential data, debugging, or as the inner content of other envelopes.

- **signed(plaintext)**:  
  - **Purpose**: Adds non-repudiation to a plaintext message; whoever receives a message wrapped in this way can prove its origin to any external party.
  - **Use case**: Audit trails, legal or regulatory messages, or when recipients need to prove message origin to third parties.

- **anoncrypt(plaintext)**:  
  - **Purpose**: Guarantees confidentiality and integrity without revealing the identity of the sender.
  - **Use case**: Anonymous tips, whistleblowing, or when sender's identity must be hidden.

- **authcrypt(plaintext)**:  
  - **Purpose**: It guarantees confidentiality and integrity. It also proves the sender's identity—but in a way that only the recipient can verify. This is the default wrapping choice that should be used unless a different goal is clearly identified.
  - **Use case**: Most secure communications where both privacy and sender authenticity are required.

- **anoncrypt(sign(plaintext))**:  
  - **Purpose**: Guarantees confidentiality, integrity, and non-repudiation – but prevents an observer of the outer envelope from accessing the signature. Relative to authcrypt(plaintext), this increases guarantees to the recipient since non-repudiation is stronger than simple authentication. However, it also forces the sender to talk “on the record” and is thus not assumed to be desirable by default.
  - **Use case**: Sensitive communications where sender wants to prove authorship to the recipient but remain anonymous to intermediaries.

- **authcrypt(sign(plaintext))**:  
  - **Purpose**: It adds no useful guarantees over the previous choice and is slightly more expensive. This wrapping combination should not be emitted by conforming implementations. However, implementations may accept it. If they choose to do so, they must emit an error if the signer of the plaintext is different from the sender identified by the authcrypt layer.
  - **Use case**: Rarely used; only for compatibility or special cases.

- **anoncrypt(authcrypt(plaintext))**:  
  - **Purpose**: A specialized combination that hides the sender key ID (skid) header in the authcrypt envelope, so the hop immediately sourceward of a mediator cannot discover an identifier for the sender.
  - **Use case**: Advanced scenarios requiring layered security and sender anonymity from intermediaries.


### Benefits of Combining Envelope Types

Refer to the table below for the benefits provided by combining each envelope type.

| Envelope Type                      | Confidentiality | Sender Authenticity | Non-repudiation | Sender Anonymity |
|------------------------------------|-----------------|---------------------|-----------------|------------------|
| plaintext (no envelope)            | ❌              | ❌                  | ❌              | ❌               |
| signed(plaintext)                  | ❌              | ✅                  | ✅              | ❌               |
| anoncrypt(plaintext)               | ✅              | ❌                  | ❌              | ✅               |
| authcrypt(plaintext)               | ✅              | ✅                  | ❌              | ❌               |
| anoncrypt(sign(plaintext))         | ✅              | ✅                  | ✅              | ✅               |
| authcrypt(sign(plaintext))         | ✅              | ✅                  | ✅              | ❌               |
| anoncrypt(authcrypt(plaintext))    | ✅              | ✅                  | ❌              | ✅               |

**In Summary**

- Use **plaintext** for non-sensitive data.
- Use **signed(plaintext)** for integrity and non-repudiation.
- Use **anoncrypt(plaintext)** for confidential, sender-anonymous messages.
- Use **authcrypt(plaintext)** for confidential, authenticated messages.
- Use **anoncrypt(sign(plaintext))** for confidential, non-repudiable, sender-anonymous messages.
- Use **authcrypt(sign(plaintext))** for the highest level of security and auditability (rarely needed).
- Use **anoncrypt(authcrypt(plaintext))** for advanced layered security and sender anonymity from intermediaries.

For more details, see the [DIDComm Messaging specification](https://identity.foundation/didcomm-messaging/spec/#iana-media-types).

## Ed25519/X25519 Curve Conversion

If you use an Ed25519 key (Edwards curve) for your DID or wallet, the Dart SSI package will use this curve for digital signatures. However, for encryption and ECDH key agreement, the Ed25519 key is automatically converted to the corresponding X25519 key. This is required because the DIDComm v2 encryption and ECDH protocols use X25519 for key agreement, not Ed25519.

When you generate a DID Document with the Dart SSI package using an Ed25519 key, the resulting DID Document will include both Ed25519 (for signing) and X25519 (for encryption/ECDH) verification methods.

- **Signing:** Uses Ed25519 (Edwards curve).
- **Encryption/ECDH:** Uses X25519, converted from Ed25519 as needed.

This conversion and DID Document construction are handled automatically by the Dart SSI and DIDComm libraries. You do not need to manually convert keys or add verification methods, but be aware that it uses the same key material in different forms for signing and encryption operations.

## Key Type Selection for Authcrypt and Anoncrypt

When encrypting messages, you must select a key type for a key agreement that all parties support.

- **Authcrypt (authenticated encryption, ECDH-1PU):**
  - For key agreement, both the sender and all recipients must use compatible key types (e.g., both must have P-256 or X25519 keys in their DID Documents).
  - You typically use the sender's wallet to find a compatible key pair and key agreement method with each recipient.
  - Use the `matchKeysInKeyAgreement` extension method to find compatible key IDs from the sender's wallet for all recipients.

- **Anoncrypt (anonymous encryption, ECDH-ES):**
  - Only uses the recipients' key agreement keys; does not involve the sender's key pair.
  - You must select a key type that all recipients for key agreement support.
  - Use the `getCommonKeyTypesInKeyAgreements` extension method on the list of recipient DID Documents to determine the set of key types common to all recipients.

Examples:

**Authcrypt:**
```dart
final compatibleKeyIds = aliceDidDocument.matchKeysInKeyAgreement(
  wallet: aliceWallet,
  otherDidDocuments: [
    bobDidDocument
    // and other recipients
  ],
);

if (compatibleKeyIds.isEmpty) {
  throw Exception('No compatible key agreement method found between Alice and Bob');
}

final aliceDidKeyId = compatibleKeyIds.first; // Use this key ID for Alice
```

**Anoncrypt:**
```dart
final commonKeyTypes = [
  bobDidDocument,
  // and other recipients
].getCommonKeyTypesInKeyAgreements();

if (commonKeyTypes.isEmpty) {
  throw Exception('No common key type found for anoncrypt between recipients');
}

final keyType = commonKeyTypes.first; // Use this key type for anoncrypt
```

This ensures that the correct and compatible keys are used for ECDH-1PU (authcrypt) and ECDH-ES (anoncrypt) operations, and that all recipients can decrypt the message using a supported key agreement method.

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

Below is a step-by-step example of secure communication between Alice and Bob using the DIDComm Dart package. The example demonstrates how to construct, sign, encrypt, and unpack messages according to the [DIDComm Messaging spec](https://identity.foundation/didcomm-messaging/spec).

### 1. Set up Wallets and DIDs

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

### 2. Compose a Plain Text Message

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

### 3. Sign the Message

Signing a message is optional in DIDComm. It is required when you need to provide non-repudiation—proof that the sender cannot deny authorship of the message. Signing a message is essential for scenarios where:

- The recipient must prove to a third party that the sender authored the message (e.g., legal, regulatory, or audit requirements).
- The message may be forwarded or relayed, and recipients must verify its origin independently of the transport channel.
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

### 4. Encrypt the Message

Although optional, encrypting DIDComm messages is highly recommended to protect their confidentiality. DIDComm supports two main types of encryption:

- **Authenticated Encryption (authcrypt, ECDH-1PU):**
  - Proves the sender's identity to the recipient (but not to intermediaries).
  - Used when both confidentiality and sender authenticity are required.
  - Only the intended recipient can read the message and verify that the sender's key encrypts the message.
  - Protects the sender's identity from intermediaries and eavesdroppers.

Choose **authcrypt** when you want the recipient to know who sent the message (authenticated, private communication).

- **Anonymous Encryption (anoncrypt, ECDH-ES):**
  - Hides the sender's identity from both the recipient and intermediaries.
  - Used when sender anonymity is required.
  - Only the intended recipient can read the message but cannot determine who sent it.

Choose **anoncrypt** when you want to keep the sender's identity hidden (anonymous tips, whistleblowing, or privacy-preserving scenarios).

#### Example: Authenticated Encryption (authcrypt)

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

#### Example: Anonymous Encryption (anoncrypt)

If you want to encrypt a message without revealing the sender's identity, use `packAnonymously`:

```dart
final anonymousEncryptedMessage = await EncryptedMessage.packAnonymously(
  message, // The signed or plain text message to encrypt
  recipientDidDocuments: [bobDidDocument], // List of recipient DID Documents
  encryptionAlgorithm: EncryptionAlgorithm.a256cbc, // Encryption algorithm
  keyType: KeyType.p256, // Key type for recipient's key agreement (required)
);
```
- `message`: The message to encrypt (can be plain or signed).
- `recipientDidDocuments`: The recipient's DID Document(s).
- `encryptionAlgorithm`: The encryption algorithm to use.
- `keyType`: The key type for the recipient's key agreement key (e.g., `KeyType.p256`, `KeyType.ed25519`).

In this case, Bob can decrypt and read the message but cannot determine who sent it. This approach is helpful for scenarios where sender anonymity is required.

### More Examples

See [`example/didcomm_example.dart`](https://github.com/affinidi/didcomm-dart/blob/main/example/didcomm_example.dart) for a complete runnable example.

For more sample usage, including a mediator workflow, see the [example folder](https://github.com/affinidi/didcomm-dart/tree/main/example).


## Pack and Unpack DIDComm Message Helpers

The `DidcommMessage` class provides high-level helper methods for common packing and unpacking workflows. These helpers simplify signing and encrypting messages according to your security and privacy requirements.

### packIntoEncryptedMessage

Packs a plain text message into an encrypted message. Use this for confidential messages (authcrypt or anoncrypt, depending on parameters).

```dart
// Authenticated encryption (authcrypt)
final encrypted = await DidcommMessage.packIntoEncryptedMessage(
  plainTextMessage,
  keyPair: aliceKeyPair,
  didKeyId: aliceDidDocument.keyAgreement[0].id,
  recipientDidDocuments: [bobDidDocument],
  keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
  encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
);

// Anonymous encryption (anoncrypt)
final anonEncrypted = await DidcommMessage.packIntoEncryptedMessage(
  plainTextMessage,
  keyType: KeyType.p256,
  recipientDidDocuments: [bobDidDocument],
  keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Es,
  encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
);
```

### packIntoSignedMessage

Packs a plain text message into a signed message. Use this for non-repudiation and message integrity.

```dart
final signed = await DidcommMessage.packIntoSignedMessage(
  plainTextMessage,
  signer: aliceSigner,
);
```

### packIntoSignedAndEncryptedMessages

Packs a plain text message into a signed message and then encrypts it. Use this for both non-repudiation and confidentiality in a single step. Encryption can be authenticated (authcrypt) or anonymous (anoncrypt), depending on the provided parameters.

```dart
// Authenticated encryption (authcrypt)
final signedAndEncrypted = await DidcommMessage.packIntoSignedAndEncryptedMessages(
  plainTextMessage,
  keyPair: aliceKeyPair,
  didKeyId: aliceDidDocument.keyAgreement[0].id,
  recipientDidDocuments: [bobDidDocument],
  keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Pu,
  encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  signer: aliceSigner,
);

// Anonymous encryption (anoncrypt)
final signedAndAnonEncrypted = await DidcommMessage.packIntoSignedAndEncryptedMessages(
  plainTextMessage,
  keyType: KeyType.p256,
  recipientDidDocuments: [bobDidDocument],
  keyWrappingAlgorithm: KeyWrappingAlgorithm.ecdh1Es,
  encryptionAlgorithm: EncryptionAlgorithm.a256cbc,
  signer: aliceSigner,
);
```

### unpackToPlainTextMessage
Bob receives the encrypted message and unpacks it:

```dart
final unpackedMessage = await DidcommMessage.unpackToPlainTextMessage(
  message: jsonDecode(sentMessageByAlice) as Map<String, dynamic>, // The received message
  recipientWallet: bobWallet, // Bob's wallet for decryption
  expectedMessageWrappingTypes: [MessageWrappingType.authcryptSignPlaintext], // Expected wrapping
  expectedSigners: [aliceSigner.didKeyId], // List of expected signers' key IDs
);
```

- `message`: The received message as a decoded JSON map.
- `recipientWallet`: The wallet instance used to decrypt the message.
- `expectedMessageWrappingTypes`: List of expected message wrapping types. This argument ensures the unpacked message matches the expected security and privacy guarantees. 

  The values are from the `MessageWrappingType` enum, which maps to the [DIDComm IANA media types](https://identity.foundation/didcomm-messaging/spec/#iana-media-types), such as `authcryptPlaintext` for authenticated encryption, `signedPlaintext` for signed messages, and `plaintext` for unprotected messages. It helps prevent downgrade attacks and ensures the message is processed as intended.

- `expectedSigners`: List of key IDs whose signatures are expected and will be verified.

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
