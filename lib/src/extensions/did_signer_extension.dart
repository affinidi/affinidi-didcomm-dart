import 'package:ssi/ssi.dart';

/// An extension on the [DidSigner] class that provides additional
/// utility methods and functionality for working with DID-based
/// signing operations.
///
/// Use this extension to enhance the capabilities of [DidSigner]
/// without modifying its original implementation.
extension DidSignerExtension on DidSigner {
  /// Returns the full DID key identifier by combining the `did` and `keyId` if `keyId` starts with '#'.
  /// If `keyId` does not start with '#', returns `keyId` as is.
  ///
  /// Example:
  /// - If `did` is 'did:example:123' and `keyId` is '#key-1', returns 'did:example:123#key-1'.
  /// - If `keyId` is 'key-1', returns 'key-1'.
  String get didKeyId => keyId.startsWith('#') ? '$did$keyId' : keyId;
}
