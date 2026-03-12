import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../sync/models/asset_timeline_local.dart';

class TimelineService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> recordEvent({
    required String assetId,
    required String action,
    String? userId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final id = const Uuid().v4();
      final event = AssetTimelineLocal(
        id: id,
        assetId: assetId,
        action: action,
        userId: userId,
        timestamp: DateTime.now(),
        details: details,
      );

      await _supabase.from('asset_timeline').insert(event.toJson());
      debugPrint('DEBUG: Recorded timeline event: $action for asset $assetId');
    } catch (e) {
      debugPrint('DEBUG: Error recording timeline event: $e');
    }
  }

  Future<List<AssetTimelineLocal>> getTimeline(String assetId) async {
    try {
      final response = await _supabase
          .from('asset_timeline')
          .select()
          .eq('asset_id', assetId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => AssetTimelineLocal.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('DEBUG: Error fetching timeline: $e');
      return [];
    }
  }

  Stream<List<AssetTimelineLocal>> getTimelineStream(String assetId) {
    return _supabase
        .from('asset_timeline')
        .stream(primaryKey: ['id'])
        .eq('asset_id', assetId)
        .order('timestamp', ascending: false)
        .map((data) => data.map((json) => AssetTimelineLocal.fromJson(json)).toList());
  }
}
