import 'package:uuid/uuid.dart';

/// Represents a Trust Task document as defined by the Trust Tasks specification.
///
/// A Trust Task document is carried as the body of a `TrustTaskMessage`.
///
/// See: https://trusttasks.org
class TrustTaskDocument {
  /// Unique identifier of the document, a `urn:uuid` URN.
  final String id;

  /// The Trust Task type URI, e.g. `https://trusttasks.org/spec/messaging/access-list/update/0.1`.
  final Uri type;

  /// DID of the party issuing the task. Must match the DIDComm sender.
  final String issuer;

  /// DID of the party the task is addressed to.
  final String recipient;

  /// Time at which the task was issued. Always stored in UTC.
  final DateTime issuedAt;

  /// The task-specific payload.
  final Map<String, dynamic> payload;

  /// Identifier of the document this one responds to, e.g. set by a mediator
  /// on its response to a task.
  final String? threadId;

  /// Data Integrity proof over the document, e.g. a mediator's signature on
  /// its response.
  ///
  /// The proof is kept as received and is not verified. Verifying it, if
  /// needed, is up to the caller; without that, the document is only as
  /// authentic as the DIDComm envelope it arrived in.
  final Map<String, dynamic>? proof;

  /// Constructs a [TrustTaskDocument].
  ///
  /// [type]: The Trust Task type URI.
  /// [issuer]: DID of the issuing party.
  /// [recipient]: DID of the receiving party.
  /// [payload]: The task-specific payload.
  /// [id]: Document identifier (optional, defaults to a fresh `urn:uuid`).
  /// [issuedAt]: Issue time (optional, defaults to now).
  /// [threadId]: Identifier of the document responded to (optional).
  /// [proof]: Data Integrity proof over the document (optional).
  TrustTaskDocument({
    required this.type,
    required this.issuer,
    required this.recipient,
    required this.payload,
    String? id,
    DateTime? issuedAt,
    this.threadId,
    this.proof,
  })  : id = id ?? 'urn:uuid:${const Uuid().v4()}',
        issuedAt = (issuedAt ?? DateTime.now()).toUtc();

  /// Creates a [TrustTaskDocument] from a JSON map, e.g. the body of a
  /// mediator's Trust Task response.
  ///
  /// [json]: The JSON map representing the document.
  ///
  /// Throws [FormatException] if a field is missing or malformed.
  factory TrustTaskDocument.fromJson(Map<String, dynamic> json) =>
      TrustTaskDocument(
        id: _field<String>(json, 'id'),
        type: Uri.parse(_field<String>(json, 'type')),
        issuer: _field<String>(json, 'issuer'),
        recipient: _field<String>(json, 'recipient'),
        issuedAt: DateTime.parse(_field<String>(json, 'issuedAt')),
        payload: _field<Map<String, dynamic>>(json, 'payload'),
        threadId: _field<String?>(json, 'threadId'),
        proof: _field<Map<String, dynamic>?>(json, 'proof'),
      );

  // Documents arrive from other parties, so a malformed one is bad input
  // rather than a programming error: report it as a FormatException instead
  // of the TypeError a plain cast would throw.
  static T _field<T>(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! T) {
      throw FormatException('Trust Task document field "$key" must be a $T');
    }

    return value;
  }

  /// Serializes the document to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'issuer': issuer,
        'recipient': recipient,
        'issuedAt': issuedAt.toIso8601String(),
        'payload': payload,
        if (threadId != null) 'threadId': threadId,
        if (proof != null) 'proof': proof,
      };
}
