import 'package:json_annotation/json_annotation.dart';

part 'problem_code.g.dart';

/// Sorter for DIDComm problem codes.
///
/// The leftmost component of a problem code is its sorter.
/// This is a single character that tells whether the consequence
/// of the problem is fully understood.
///
/// - 'e': This problem clearly defeats the intentions of at least
///   one of the parties. It is therefore an error.
/// - 'w': The consequences of this problem are not obvious to the
///   reporter; evaluating its effects requires judgment from a human
///   or from some other party or system. Thus, the message constitutes
///   a warning from the sender’s perspective.
@JsonEnum(alwaysCreate: true)
enum SorterType {
  /// Error: This problem clearly defeats the intentions of at least
  /// one of the parties. It is therefore an error.
  @JsonValue('e')
  error,

  /// Warning: The consequences of this problem are not obvious to the
  /// reporter; evaluating its effects requires judgment from a human or
  /// from some other party or system. Thus, the message constitutes a
  /// warning from the sender’s perspective.
  @JsonValue('w')
  warning,

  /// Indicates that the sorter code is unrecognized or not defined in the current context.
  unrecognized;

  /// Returns the string representation of the current enum value.
  /// This is typically used for serialization
  /// or for obtaining a standardized code associated with the enum.
  String get code => _$SorterTypeEnumMap[this]!;
}

/// Scope for DIDComm problem codes.
///
/// The second token in a problem code is called the scope.
/// This gives the sender’s opinion about how much context should be
/// undone if the problem is deemed an error.
///
/// - 'p': The protocol within which the error occurs (and any co-protocols
///   started by and depended on by the protocol) is abandoned or reset.
/// - 'm': The error was triggered by the previous message on the thread;
///   the scope is one message. The outcome is that the problematic message
///   is rejected (has no effect).
@JsonEnum(alwaysCreate: true)
enum ScopeType {
  /// The protocol within which the error occurs (and any co-protocols
  /// started by and depended on by the protocol) is abandoned or reset.
  @JsonValue('p')
  protocol,

  /// The error was triggered by the previous message on the thread;
  /// the scope is one message. The outcome is that the problematic
  /// message is rejected (has no effect).
  @JsonValue('m')
  message,

  /// Indicates that the scope code is unrecognized or not defined in the current context.
  unrecognized;

  /// Returns the string representation of the current enum value.
  String get code => _$ScopeTypeEnumMap[this]!;
}

/// Descriptors for DIDComm problem reports as defined in the DIDComm Messaging spec.
///
/// After the sorter and the scope, problem codes consist of one or more
/// descriptors. These are kebab-case tokens separated by the `.` character,
/// where the semantics get progressively more detailed reading left to right.
///
/// The following descriptor tokens are defined in the spec. They can be used
/// by themselves, or as prefixes to more specific descriptors. Additional
/// descriptors—particularly more granular ones—may be defined in individual
/// protocols.
@JsonEnum(alwaysCreate: true)
enum DescriptorType {
  /// trust: Failed to achieve required trust.
  /// Typically this code indicates incorrect or suboptimal behavior by the
  /// sender of a previous message in a protocol. For example, a protocol
  /// required a known sender but a message arrived anoncrypted instead — or
  /// the encryption is well formed and usable, but is considered weak.
  /// Problems with this descriptor are similar to those reported by HTTP’s
  /// 401, 403, or 407 status codes.
  trust,

  /// trust.crypto: Cryptographic operation failed.
  /// A cryptographic operation cannot be performed, or it gives results
  /// that indicate tampering or incorrectness. For example, a key is invalid
  /// — or the key types used by another party are not supported — or a
  /// signature doesn’t verify — or a message won’t decrypt with the specified key.
  @JsonValue('trust.crypto')
  trustCrypto,

  /// xfer: Unable to transport data.
  /// The problem is with the mechanics of moving messages or associated data
  /// over a transport. For example, the sender failed to download an external
  /// attachment — or attempted to contact an endpoint, but found nobody
  /// listening on the specified port.
  xfer,

  /// did: DID is unusable.
  /// A DID is unusable because its method is unsupported — or because its
  /// DID doc cannot be parsed — or because its DID doc lacks required data.
  did,

  /// msg: Bad message.
  /// Something is wrong with content as seen by application-level protocols
  /// (i.e., in a plaintext message). For example, the message might lack a
  /// required field, use an unsupported version, or hold data with logical
  /// contradictions. Problems in this category resemble HTTP’s 400 status code.
  @JsonValue('msg')
  message,

  /// me: Internal error.
  /// The problem is with conditions inside the problem sender’s system.
  /// For example, the sender is too busy to do the work entailed by the next
  /// step in the active protocol. Problems in this category resemble HTTP’s
  /// 5xx status codes.
  me,

  /// me.res: A required resource is inadequate or unavailable.
  @JsonValue('me.res')
  meResource,

  /// req: Circumstances don’t satisfy requirements.
  /// A behavior occurred out of order or without satisfying certain
  /// preconditions — or circumstances changed in a way that violates
  /// constraints. For example, a protocol that books plane tickets fails
  /// because, halfway through, it is discovered that all tickets on the
  /// flight have been sold.
  requirement,

  /// req.time: Failed to satisfy timing constraints.
  /// A message has expired — or a protocol has timed out — or it is the
  /// wrong time of day/day of week.
  @JsonValue('req.time')
  requirementTime,

  /// legal: Failed for legal reasons.
  /// An injunction or a regulatory requirement prevents progress on the
  /// workflow. Compare HTTP status code 451.
  legal;

  /// Returns the string representation of the current enum value.
  String get code => _$DescriptorTypeEnumMap[this]!;
}

/// Scope information for a problem code.
class Scope {
  /// The scope type (protocol, message, or state name).
  final ScopeType? scope;

  /// The formal state name from the sender’s state machine in the active protocol.
  final String? stateName;

  /// Creates a new instance of [Scope].
  ///
  /// The [Scope] constructor is used to initialize the scope of a problem code,
  /// which typically defines the context or domain in which the problem occurred.
  ///
  /// Additional parameters and usage details should be provided based on the
  /// implementation of the [Scope] class.
  Scope({
    this.scope,
    this.stateName,
  });

  /// Returns the scope code if defined, otherwise the state name.
  /// Throws an [ArgumentError] if neither is provided.
  String get code {
    if (scope != null) {
      return _$ScopeTypeEnumMap[scope]!;
    }

    if (stateName != null) {
      return stateName!;
    }

    throw ArgumentError(
      'Scope must be provided or stateName must not be null',
    );
  }
}

/// Represents a DIDComm problem code, including sorter and scope.
class ProblemCode {
  /// The sorter (error or warning).
  final SorterType sorter;

  /// The scope of the problem.
  final Scope scope;

  /// A list of string descriptors providing additional details or context.
  ///
  /// Each descriptor in the list represents a specific aspect or attribute
  /// related to the problem code, allowing for more granular reporting or
  /// categorization of issues.
  final List<String> descriptors;

  /// Creates a new instance of [ProblemCode].
  ///
  /// This constructor is used to initialize a [ProblemCode] object,
  /// which represents a specific problem code within the problem report protocol.
  ///
  /// You can provide additional parameters to further specify the details
  /// of the problem code as required by the protocol.
  ProblemCode({
    required this.sorter,
    required this.scope,
    required this.descriptors,
  });
}
