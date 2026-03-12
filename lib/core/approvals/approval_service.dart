import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../sync/models/approval_local.dart';

class ApprovalService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> requestApproval({
    required String assetId,
    required String requestedBy,
    required String actionType,
    Map<String, dynamic>? details,
  }) async {
    try {
      final id = const Uuid().v4();
      final request = ApprovalLocal(
        id: id,
        assetId: assetId,
        requestedBy: requestedBy,
        actionType: actionType,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        details: details,
      );

      await _supabase.from('approvals').insert(request.toJson());
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DEBUG: Error requesting approval: $e');
      return false;
    }
  }

  Future<bool> updateApprovalStatus({
    required String requestId,
    required String status,
    required String approvedBy,
  }) async {
    try {
      await _supabase.from('approvals').update({
        'status': status,
        'approved_by': approvedBy,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DEBUG: Error updating approval status: $e');
      return false;
    }
  }

  Stream<List<ApprovalLocal>> getPendingApprovalsStream() {
    return _supabase
        .from('approvals')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => ApprovalLocal.fromJson(json)).toList());
  }

  Future<List<ApprovalLocal>> getApprovalsForAsset(String assetId) async {
    try {
      final response = await _supabase
          .from('approvals')
          .select()
          .eq('asset_id', assetId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ApprovalLocal.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('DEBUG: Error fetching approvals for asset: $e');
      return [];
    }
  }
}
