import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:assets_management/core/approvals/approval_service.dart';
import 'package:assets_management/core/auth/auth_service.dart';
import 'package:assets_management/core/assets/asset_service.dart';
import 'package:assets_management/core/timeline/timeline_service.dart';
import 'package:assets_management/core/sync/models/approval_local.dart';
import 'package:assets_management/core/theme/app_colors.dart';

class ApprovalDashboardScreen extends StatelessWidget {
  const ApprovalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        elevation: 0,
        backgroundColor: cs.surface,
      ),
      body: StreamBuilder<List<ApprovalLocal>>(
        stream: context.read<ApprovalService>().getPendingApprovalsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending approval requests',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _ApprovalRequestCard(request: request);
            },
          );
        },
      ),
    );
  }
}

class _ApprovalRequestCard extends StatelessWidget {
  final ApprovalLocal request;
  const _ApprovalRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (request.actionType == 'dispose' ? AppColors.danger : AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    request.actionType == 'dispose' ? Icons.delete_forever_rounded : Icons.swap_horiz_rounded,
                    color: request.actionType == 'dispose' ? AppColors.danger : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.details?['assetName'] ?? 'Unknown Asset',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Requested by: ${request.requestedBy}',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(request.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            if (request.actionType == 'transfer') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Transfer to: ${request.details?['destination'] ?? 'N/A'}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(context, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(context, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String status) async {
    final auth = context.read<AuthService>();
    final approval = context.read<ApprovalService>();
    final assetService = context.read<AssetService>();
    final timeline = context.read<TimelineService>();

    final success = await approval.updateApprovalStatus(
      requestId: request.id,
      status: status,
      approvedBy: auth.firebaseUser?.uid ?? 'admin',
    );

    if (success && status == 'approved') {
      // Execute the actual action
      if (request.actionType == 'dispose') {
        await assetService.deleteAsset(request.assetId);
        await timeline.recordEvent(
          assetId: request.assetId,
          action: 'disposed',
          userId: auth.firebaseUser?.uid,
          details: {'note': 'Action approved by manager'},
        );
      } else if (request.actionType == 'transfer') {
        // Find asset and update location
        final asset = await assetService.findAssetByNameOrId(request.assetId);
        if (asset != null) {
          final updatedAsset = asset.copyWith(location: request.details?['destination']);
          await assetService.updateAsset(updatedAsset);
          await timeline.recordEvent(
            assetId: request.assetId,
            action: 'transferred',
            userId: auth.firebaseUser?.uid,
            details: {
              'note': 'Action approved by manager',
              'destination': request.details?['destination'],
            },
          );
        }
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status')),
      );
    }
  }
}
