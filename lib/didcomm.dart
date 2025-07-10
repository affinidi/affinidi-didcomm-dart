/// Affinidi DIDComm for Dart
///
/// A Dart library for secure, private, and verifiable communication using the DIDComm v2 Messaging protocol.
///
/// This package provides tools for constructing, signing, encrypting, and unpacking DIDComm messages, supporting multiple DID methods and cryptographic algorithms. It enables confidential, authenticated, and non-repudiable messaging between decentralized identities.

library;

export 'src/converters/jwe_header_converter.dart';
export 'src/errors/errors.dart';
export 'src/extensions/affinidi_authenticator_extension.dart';
export 'src/extensions/did_manager_extension.dart';
export 'src/extensions/did_document_extension.dart';
export 'src/extensions/verification_method_extention.dart';
export 'src/mediator_client.dart';
export 'src/messages/algorithm_types/algorithms_types.dart';
export 'src/messages/attachments.dart';
export 'src/messages/core.dart';
export 'src/messages/didcomm_message.dart';
export 'src/messages/message_wrapping_type.dart';
export 'src/messages/protocols.dart';
