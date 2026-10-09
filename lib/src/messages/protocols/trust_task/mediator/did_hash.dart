import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Returns the identifier an Affinidi mediator uses for [did]: the hex encoded
/// SHA-256 hash of the DID string.
String mediatorDidHash(String did) =>
    sha256.convert(utf8.encode(did)).toString();
