import '../trust_task_document.dart';
import 'did_hash.dart';
import 'mediator_acl.dart';

/// The `messaging/account/update` Trust Task of an Affinidi mediator, used to
/// change a DID's ACL.
///
/// Only the flags set in the [MediatorAcl] are changed. A non-admin DID may only
/// update its own account and only flags it is allowed to self-change.
class AccountUpdateTask extends TrustTaskDocument {
  /// The Trust Task type URI.
  static final taskType = Uri.parse(
    'https://trusttasks.org/spec/messaging/account/update/0.1',
  );

  /// Constructs an [AccountUpdateTask].
  ///
  /// [issuer]: DID sending the task.
  /// [mediatorDid]: DID of the mediator.
  /// [acl]: The ACL flags to change.
  /// [targetDid]: DID whose account is updated (optional, defaults to [issuer]).
  ///
  /// Throws [ArgumentError] if [acl] sets no flag.
  AccountUpdateTask({
    required super.issuer,
    required String mediatorDid,
    required MediatorAcl acl,
    String? targetDid,
    super.id,
    super.issuedAt,
  }) : super(
          type: taskType,
          recipient: mediatorDid,
          payload: {
            'did': mediatorDidHash(targetDid ?? issuer),
            'acl': _requireFlags(acl),
          },
        );

  static Map<String, dynamic> _requireFlags(MediatorAcl acl) {
    final flags = acl.toJson();
    if (flags.isEmpty) {
      throw ArgumentError.value(acl, 'acl', 'Set at least one ACL flag');
    }
    return flags;
  }
}
