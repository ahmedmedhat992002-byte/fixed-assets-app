import 'package:hive_flutter/hive_flutter.dart';
import 'package:assets_management/core/sync/models/sync_operation.dart';

/// Wraps the Hive 'sync_ops' box and provides a clean enqueue/dequeue API.
/// Operations are stored locally and survive app restarts.
class OperationQueue {
  static const _boxName = 'sync_ops';

  late Box<SyncOperation> _box;

  /// Must be called once after [Hive.initFlutter()].
  Future<void> init() async {
    _box = await Hive.openBox<SyncOperation>(_boxName);
  }

  /// Adds an operation to the persistent queue.
  Future<void> enqueue(SyncOperation op) async {
    await _box.put(op.operationId, op);
  }

  /// Returns all operations that have not yet been confirmed by the server,
  /// ordered by client-side timestamp (oldest first).
  List<SyncOperation> pendingOps() {
    final ops = _box.values.where((op) => !op.synced).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ops;
  }

  /// Marks the given operation IDs as synced and removes them from the box.
  Future<void> markSynced(List<String> ids) async {
    for (final id in ids) {
      await _box.delete(id);
    }
  }

  /// Increments the retry counter for a failed operation.
  Future<void> incrementRetry(String operationId) async {
    final op = _box.get(operationId);
    if (op != null) {
      op.retryCount++;
      await op.save();
    }
  }

  /// Removes an operation from the queue (e.g. after permanent failure).
  Future<void> remove(String operationId) async {
    await _box.delete(operationId);
  }

  int get pendingCount => pendingOps().length;
}
