import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:assets_management/core/sync/models/asset_local.dart';
import 'package:assets_management/core/sync/models/sync_operation.dart';
import 'package:assets_management/core/sync/conflict_resolver.dart';
import 'package:assets_management/core/sync/operation_queue.dart';

/// The central sync layer.
///
/// Usage:
/// ```dart
/// // On asset update:
/// await syncService.queueOperation(op);
///
/// // Flush is automatic when online, or call manually:
/// await syncService.flush();
/// ```
class SyncService extends ChangeNotifier {
  SyncService({required this.queue, required this.companyId});

  final OperationQueue queue;
  final String companyId;

  bool _flushing = false;
  bool get isFlushing => _flushing;

  SyncResult? _lastResult;
  SyncResult? get lastResult => _lastResult;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Call once after init to start auto-flush on connectivity restore.
  void startConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && queue.pendingCount > 0) {
        await flush();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Persists [op] locally and attempts an immediate flush if online.
  Future<void> queueOperation(SyncOperation op) async {
    await queue.enqueue(op);
    notifyListeners();
    // Attempt flush (no-op if offline or already flushing).
    unawaited(_tryFlush());
  }

  /// Sends all pending operations to the [syncBatch] Cloud Function.
  Future<SyncResult?> flush() => _tryFlush(force: true);

  /// Pulls the latest asset list from Firestore and repopulates the Hive box.
  /// Call after first login or after unresolvable conflicts.
  Future<void> pullLatest() async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('assets')
        .get();

    final box = Hive.box<AssetLocal>('assets');
    for (final doc in snap.docs) {
      final data = doc.data();
      final asset = AssetLocal(
        id: doc.id,
        companyId: companyId,
        name: data['name'] as String? ?? '',
        category: data['category'] as String? ?? '',
        status: data['status'] as String? ?? 'active',
        purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0,
        currentValue: (data['currentValue'] as num?)?.toDouble() ?? 0,
        depreciationMethod:
            data['depreciationMethod'] as String? ?? 'straight_line',
        location: data['location'] as String?,
        assignedTo: data['assignedTo'] as String?,
        description: data['description'] as String?,
        version: (data['version'] as num?)?.toInt() ?? 0,
        isDirty: false,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await box.put(doc.id, asset);
    }
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<SyncResult?> _tryFlush({bool force = false}) async {
    if (_flushing && !force) return null;

    final pending = queue.pendingOps();
    if (pending.isEmpty) return null;

    // Check connectivity before attempting.
    final connectivity = await Connectivity().checkConnectivity();
    final online = connectivity.any((r) => r != ConnectivityResult.none);
    if (!online) return null;

    _flushing = true;
    notifyListeners();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('syncBatch');
      final response = await callable.call({
        'operations': pending.map((op) => op.toMap()).toList(),
      });

      final result = SyncResult.fromMap(response.data as Map<dynamic, dynamic>);

      // Mark applied ops as done.
      await queue.markSynced(result.applied);

      // Handle conflicts: last-write-wins re-queue.
      for (final conflict in result.conflicts) {
        final original = pending.firstWhere(
          (op) => op.operationId == conflict.operationId,
          orElse: () => throw StateError(
            'conflict for unknown op ${conflict.operationId}',
          ),
        );

        final merged = ConflictResolver.mergeLastWriteWins(
          clientPayload: original.payload,
          serverData: conflict.serverData,
        );

        final requeued = SyncOperation(
          operationId: original.operationId,
          type: 'update',
          collection: original.collection,
          documentId: original.documentId,
          payload: merged,
          baseVersion: conflict.serverVersion, // use server's current version
          deviceId: original.deviceId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        await queue.remove(original.operationId);
        await queue.enqueue(requeued);
      }

      // Increment retry counters for permanently failed ops.
      for (final failed in result.failed) {
        await queue.incrementRetry(failed.operationId);
      }

      _lastResult = result;
      return result;
    } catch (e) {
      debugPrint('[SyncService] flush error: $e');
      return null;
    } finally {
      _flushing = false;
      notifyListeners();
    }
  }
}
