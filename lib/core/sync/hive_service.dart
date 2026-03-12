import 'package:hive_flutter/hive_flutter.dart';

import '../sync/models/asset_local.dart';
import '../sync/models/company_user_local.dart';
import '../sync/models/sync_operation.dart';
import '../sync/models/approval_local.dart';
import '../sync/models/asset_timeline_local.dart';

/// Initializes Hive and registers all type adapters.
/// Call before [runApp] (after [Firebase.initializeApp()]).
class HiveService {
  static const _boxes = ['assets', 'sync_ops', 'current_user', 'approvals', 'asset_timeline'];

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register generated adapters (from build_runner).
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(AssetLocalAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CompanyUserLocalAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(ApprovalLocalAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(AssetTimelineLocalAdapter());
    }

    // Open all boxes eagerly so they're ready before first frame.
    await Future.wait([
      Hive.openBox<SyncOperation>('sync_ops'),
      Hive.openBox<AssetLocal>('assets'),
      Hive.openBox<CompanyUserLocal>('current_user'),
      Hive.openBox<ApprovalLocal>('approvals'),
      Hive.openBox<AssetTimelineLocal>('asset_timeline'),
    ]);
  }

  /// Clears all Hive data (e.g. on sign-out).
  static Future<void> clear() async {
    for (final name in _boxes) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
      }
    }
  }
}
