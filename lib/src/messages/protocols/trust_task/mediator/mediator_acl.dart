/// Access-list mode of a DID on an Affinidi mediator.
enum AccessListMode {
  /// Only DIDs on the access list may send messages to the DID.
  explicitAllow,

  /// All DIDs except those on the access list may send messages to the DID.
  explicitDeny,
}

/// ACL flags of a DID on an Affinidi mediator, as used by the
/// `messaging/account/update` Trust Task.
///
/// Every flag is optional; only set flags are sent, so a task changes exactly
/// the flags it names. A non-admin DID may only change flags it is allowed to
/// self-change; the mediator rejects any other change.
class MediatorAcl {
  /// Which senders may message the DID.
  final AccessListMode? accessListMode;

  /// Whether the DID is blocked. Admin only.
  final bool? blocked;

  /// Whether the DID has an inbox on the mediator. Admin only.
  final bool? local;

  /// Whether the DID may send messages.
  final bool? sendMessages;

  /// Whether the DID may receive messages.
  final bool? receiveMessages;

  /// Whether the DID may send forwarded messages.
  final bool? sendForwarded;

  /// Whether the DID may receive forwarded messages.
  final bool? receiveForwarded;

  /// Whether the DID may create out-of-band invitations.
  final bool? createInvites;

  /// Whether the DID may receive anonymous messages.
  final bool? anonReceive;

  /// Whether the DID may manage its own access list. Admin only.
  final bool? selfManageList;

  /// Whether the DID may set its own send queue limit. Admin only.
  final bool? selfManageSendQueueLimit;

  /// Whether the DID may set its own receive queue limit. Admin only.
  final bool? selfManageReceiveQueueLimit;

  /// Constructs a [MediatorAcl] with the flags to set.
  const MediatorAcl({
    this.accessListMode,
    this.blocked,
    this.local,
    this.sendMessages,
    this.receiveMessages,
    this.sendForwarded,
    this.receiveForwarded,
    this.createInvites,
    this.anonReceive,
    this.selfManageList,
    this.selfManageSendQueueLimit,
    this.selfManageReceiveQueueLimit,
  });

  /// Serializes the set flags to a JSON map. Unset flags are omitted.
  Map<String, dynamic> toJson() => {
        if (accessListMode != null) 'accessListMode': accessListMode!.name,
        if (blocked != null) 'blocked': blocked,
        if (local != null) 'local': local,
        if (sendMessages != null) 'sendMessages': sendMessages,
        if (receiveMessages != null) 'receiveMessages': receiveMessages,
        if (sendForwarded != null) 'sendForwarded': sendForwarded,
        if (receiveForwarded != null) 'receiveForwarded': receiveForwarded,
        if (createInvites != null) 'createInvites': createInvites,
        if (anonReceive != null) 'anonReceive': anonReceive,
        if (selfManageList != null) 'selfManageList': selfManageList,
        if (selfManageSendQueueLimit != null)
          'selfManageSendQueueLimit': selfManageSendQueueLimit,
        if (selfManageReceiveQueueLimit != null)
          'selfManageReceiveQueueLimit': selfManageReceiveQueueLimit,
      };
}
