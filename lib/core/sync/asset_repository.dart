import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../sync/models/asset_local.dart';
import '../sync/models/sync_operation.dart';
import '../sync/sync_service.dart';

/// Offline-first repository for assets.
///
/// ALL reads come from Hive. ALL writes go:
///   1. Hive (immediate) → isDirty = true
///   2. SyncService.queueOperation() → will flush to Cloud Function when online
///
/// Direct Firestore writes are FORBIDDEN here.
class AssetRepository {
  AssetRepository({required this.syncService, required this.deviceId});

  final SyncService syncService;
  final String deviceId;

  Box<AssetLocal> get _box => Hive.box<AssetLocal>('assets');
  final _uuid = const Uuid();

  // ── Reads ─────────────────────────────────────────────────────────────────

  List<AssetLocal> getAll() => _box.values.toList();

  AssetLocal? getById(String id) => _box.get(id);

  List<AssetLocal> getByCategory(String category) =>
      _box.values.where((a) => a.category == category).toList();

  List<AssetLocal> getByStatus(String status) =>
      _box.values.where((a) => a.status == status).toList();

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Creates a new asset locally and enqueues a create operation.
  Future<AssetLocal> createAsset(Map<String, dynamic> fields) async {
    final id = fields['id'] as String? ?? _uuid.v4();
    final companyId = syncService.companyId;
    final now = DateTime.now().millisecondsSinceEpoch;

    final asset = AssetLocal(
      id: id,
      companyId: companyId,
      name: fields['name'] as String,
      category: fields['category'] as String,
      status: 'active',
      purchasePrice: (fields['purchasePrice'] as num?)?.toDouble() ?? 0,
      currentValue: (fields['currentValue'] as num?)?.toDouble() ?? 0,
      depreciationMethod:
          fields['depreciationMethod'] as String? ?? 'straight_line',
      location: fields['location'] as String?,
      assignedTo: fields['assignedTo'] as String?,
      description: fields['description'] as String?,
      version: 0,
      isDirty: true,
      updatedAtMs: now,
    );

    await _box.put(id, asset);

    await syncService.queueOperation(
      SyncOperation(
        operationId: _uuid.v4(),
        type: 'create',
        collection: 'assets',
        documentId: id,
        payload: {...fields, 'id': id, 'companyId': companyId},
        baseVersion: 0,
        deviceId: deviceId,
        timestamp: now,
      ),
    );

    return asset;
  }

  /// Updates an existing asset locally and enqueues an update operation.
  Future<AssetLocal> updateAsset(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final existing = _box.get(id);
    if (existing == null) throw StateError('Asset $id not found locally');

    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = existing.copyWith(
      name: changes['name'] as String?,
      category: changes['category'] as String?,
      status: changes['status'] as String?,
      location: changes['location'] as String?,
      assignedTo: changes['assignedTo'] as String?,
      purchasePrice: (changes['purchasePrice'] as num?)?.toDouble(),
      currentValue: (changes['currentValue'] as num?)?.toDouble(),
      depreciationMethod: changes['depreciationMethod'] as String?,
      description: changes['description'] as String?,
      isDirty: true,
    );

    await _box.put(id, updated);

    await syncService.queueOperation(
      SyncOperation(
        operationId: _uuid.v4(),
        type: 'update',
        collection: 'assets',
        documentId: id,
        payload: changes,
        baseVersion: existing.version,
        deviceId: deviceId,
        timestamp: now,
      ),
    );

    return updated;
  }

  /// Soft-deletes (disposes) the asset locally and enqueues a delete operation.
  Future<void> disposeAsset(String id) async {
    final existing = _box.get(id);
    if (existing == null) return;

    // Mark as disposed locally.
    await updateAsset(id, {'status': 'disposed'});

    // Also enqueue a delete so Firestore removes it.
    await syncService.queueOperation(
      SyncOperation(
        operationId: _uuid.v4(),
        type: 'delete',
        collection: 'assets',
        documentId: id,
        payload: {},
        baseVersion: existing.version,
        deviceId: deviceId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Assigns an asset to a user — always generates an 'assign' event.
  Future<AssetLocal> assignAsset(String id, String assignedToUid) =>
      updateAsset(id, {'assignedTo': assignedToUid, 'eventType': 'assign'});

  /// Transfers an asset to a new location.
  Future<AssetLocal> transferAsset(String id, String newLocation) =>
      updateAsset(id, {'location': newLocation, 'eventType': 'transfer'});

  /// Sets asset status to 'maintenance'.
  Future<AssetLocal> sendToMaintenance(String id) =>
      updateAsset(id, {'status': 'maintenance', 'eventType': 'maintenance'});
}
