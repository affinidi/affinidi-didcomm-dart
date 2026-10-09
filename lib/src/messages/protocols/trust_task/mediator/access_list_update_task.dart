import '../trust_task_document.dart';
import 'did_hash.dart';

/// The `messaging/access-list/update` Trust Task of an Affinidi mediator.
///
/// Changes which senders may message a DID. Applied in the order clear, add,
/// remove. A non-admin DID may only update its own access list.
class AccessListUpdateTask extends TrustTaskDocument {
  /// The Trust Task type URI.
  static final taskType = Uri.parse(
    'https://trusttasks.org/spec/messaging/access-list/update/0.1',
  );

  /// Constructs an [AccessListUpdateTask].
  ///
  /// [issuer]: DID sending the task.
  /// [mediatorDid]: DID of the mediator.
  /// [targetDid]: DID whose access list is updated (optional, defaults to [issuer]).
  /// [add]: DIDs to add to the access list.
  /// [remove]: DIDs to remove from the access list.
  /// [clear]: Whether to clear the access list first.
  ///
  /// Throws [ArgumentError] if the task would change nothing.
  AccessListUpdateTask({
    required super.issuer,
    required String mediatorDid,
    String? targetDid,
    List<String> add = const [],
    List<String> remove = const [],
    bool clear = false,
    super.id,
    super.issuedAt,
  }) : super(
          type: taskType,
          recipient: mediatorDid,
          payload: {
            'did': mediatorDidHash(targetDid ?? issuer),
            if (clear) 'clear': true,
            if (add.isNotEmpty) 'add': add.map(mediatorDidHash).toList(),
            if (remove.isNotEmpty)
              'remove': remove.map(mediatorDidHash).toList(),
          },
        ) {
    if (!clear && add.isEmpty && remove.isEmpty) {
      throw ArgumentError('Set clear, add or remove to update the access list');
    }
  }
}
