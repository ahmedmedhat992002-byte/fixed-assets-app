import 'package:flutter/material.dart';
import 'package:assets_management/core/maintenance/maintenance_service.dart';
import 'package:assets_management/core/sync/models/maintenance_local.dart';
import 'package:intl/intl.dart';
import 'package:assets_management/core/theme/app_colors.dart';
import 'package:assets_management/core/sync/models/asset_local.dart';
import 'package:assets_management/core/sync/models/asset_timeline_local.dart';
import 'package:assets_management/core/timeline/timeline_service.dart';
import 'package:assets_management/core/approvals/approval_service.dart';
import 'package:assets_management/core/auth/auth_service.dart';
import 'package:assets_management/app/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:assets_management/core/files/files_service.dart';
import 'dart:io';

class UnifiedAssetDetailScreen extends StatefulWidget {
  const UnifiedAssetDetailScreen({super.key, required this.asset});

  final AssetLocal asset;

  @override
  State<UnifiedAssetDetailScreen> createState() =>
      _UnifiedAssetDetailScreenState();
}

class _UnifiedAssetDetailScreenState extends State<UnifiedAssetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.primary),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.manualSearch),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.5),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with Title and Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(widget.asset.category),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.asset.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                _ActionIcon(
                  icon: Icons.edit_rounded,
                  onTap: () async {
                    final updated = await Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.addAsset, arguments: widget.asset);
                    if (updated == true && mounted) {
                      // Note: Data is usually updated via a stream in a real app
                    }
                  },
                ),
                const SizedBox(width: 8),
                _ActionIcon(
                  icon: Icons.swap_horiz_rounded,
                  onTap: () => _handleTransferRequest(context),
                ),
                const SizedBox(width: 8),
                _ActionIcon(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  onTap: () => _handleDisposalRequest(context),
                ),
              ],
            ),
          ),

          // Custom TabBar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: cs.onSurfaceVariant.withValues(alpha: 0.7),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Maintenance'),
              Tab(text: 'Location History'),
              Tab(text: 'Depreciation'),
              Tab(text: 'Documents'),
              Tab(text: 'Financial'),
              Tab(text: 'Timeline'),
            ],
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(asset: widget.asset),
                _MaintenanceTab(asset: widget.asset),
                _LocationHistoryTab(asset: widget.asset),
                _DepreciationTab(asset: widget.asset),
                _DocumentsTab(asset: widget.asset),
                _FinancialInfoTab(asset: widget.asset),
                _TimelineTab(asset: widget.asset),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDisposalRequest(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Disposal'),
        content: Text('Are you sure you want to request disposal for ${widget.asset.name}? This will require manager approval.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Request', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (!context.mounted) return;
      final auth = context.read<AuthService>();
      final approval = context.read<ApprovalService>();
      
      final success = await approval.requestApproval(
        assetId: widget.asset.id,
        requestedBy: auth.firebaseUser?.uid ?? 'unknown',
        actionType: 'dispose',
        details: {'assetName': widget.asset.name},
      );

      if (mounted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Disposal request sent' : 'Failed to send request')),
        );
      }
    }
  }

  Future<void> _handleTransferRequest(BuildContext context) async {
    final destinationController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the destination for this asset:'),
            const SizedBox(height: 12),
            TextField(
              controller: destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination (e.g., Dept B, Cairo Branch)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (destinationController.text.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destination is required')),
        );
        return;
      }

      if (!context.mounted) return;
      final auth = context.read<AuthService>();
      final approval = context.read<ApprovalService>();
      
      final success = await approval.requestApproval(
        assetId: widget.asset.id,
        requestedBy: auth.firebaseUser?.uid ?? 'unknown',
        actionType: 'transfer',
        details: {
          'assetName': widget.asset.name,
          'destination': destinationController.text,
        },
      );

      if (mounted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Transfer request sent' : 'Failed to send request')),
        );
      }
    }
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionIcon({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? AppColors.primary, size: 22),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.asset});
  final AssetLocal asset;

  String _formatDate(int? ms) {
    if (ms == null || ms == 0) return 'Not set';
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(asset.category),
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        asset.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Category',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        asset.category,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _DetailRow(label: 'Location', value: asset.location ?? 'Not set'),
          _DetailRow(
            label: 'Purchase Date',
            value: _formatDate(asset.purchaseDateMs),
          ),
          _DetailRow(
            label: 'Useful Life',
            value: '${asset.usefulLife ?? 0} Years',
          ),
          _DetailRow(
            label: 'Purchase Value',
            value:
                'LE ${asset.purchasePrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
          ),
          _DetailRow(
            label: 'Book Value',
            value:
                'LE ${asset.currentValue.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
            valueColor: AppColors.primary,
          ),

          // Status Row
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (asset.status.toLowerCase() == 'active'
                                ? AppColors.success
                                : AppColors.danger)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    asset.status.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: asset.status.toLowerCase() == 'active'
                          ? AppColors.success
                          : AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          Text(
            'Asset Description',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            asset.description?.isNotEmpty == true
                ? asset.description!
                : 'No additional description provided.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Map Section
          Text(
            'Location Preview',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.1),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: _buildMapPreview(asset.location, cs),
            ),
          ),

          const SizedBox(height: 32),

          // QR Code Section
          Text(
            'Asset ID & QR',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 120, color: cs.onSurface),
                  const SizedBox(height: 12),
                  Text(
                    asset.id,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMapPreview(String? location, ColorScheme cs) {
    final coords = _parseCoordinates(location);
    if (coords == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              location ?? 'No location set',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: coords,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.assets_management.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: coords,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }

  LatLng? _parseCoordinates(String? location) {
    if (location == null) return null;
    final parts = location.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }
}

IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'vehicles':
    case 'vehicle':
      return Icons.directions_car_rounded;
    case 'machinery':
    case 'machines':
      return Icons.settings_suggest_rounded;
    case 'computer hardware':
    case 'hardware':
    case 'computers':
      return Icons.computer_rounded;
    case 'furniture':
      return Icons.chair_rounded;
    case 'intangible':
    case 'intangible assets':
      return Icons.verified_user_rounded;
    case 'land':
    case 'real estate':
      return Icons.landscape_rounded;
    default:
      return Icons.business_rounded;
  }
}

// ── Depreciation Tab ──────────────────────────────────────────────────────────
class _DepreciationTab extends StatelessWidget {
  const _DepreciationTab({required this.asset});
  final AssetLocal asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(
      symbol: 'LE ',
      decimalDigits: 0,
      locale: 'en_US',
    );

    final purchasePrice = asset.purchasePrice;
    final salvageValue = asset.salvageValue ?? 0.0;
    final usefulLife = asset.usefulLife ?? 5;
    final annualDepreciation = (purchasePrice - salvageValue) / usefulLife;
    final accumulatedDepr = asset.getEstimatedDepreciation();

    final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
      asset.purchaseDateMs ?? DateTime.now().millisecondsSinceEpoch,
    );
    final startYear = purchaseDate.year;

    final scheduleItems = List.generate(usefulLife, (index) {
      final year = startYear + index;
      final openingValue = purchasePrice - (annualDepreciation * index);
      final closingValue = openingValue - annualDepreciation;
      return (
        year.toString(),
        currencyFormat.format(openingValue),
        currencyFormat.format(closingValue.clamp(salvageValue, purchasePrice)),
        currencyFormat.format(annualDepreciation),
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Summary',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.depreciationSchedule,
                        arguments: asset,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Full View'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Method',
                  value: asset.depreciationMethod
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map(
                        (s) => s.isEmpty
                            ? ''
                            : s[0].toUpperCase() + s.substring(1).toLowerCase(),
                      )
                      .join(' '),
                ),
                _DetailRow(
                  label: 'Annual Expense',
                  value: currencyFormat.format(annualDepreciation),
                ),
                _DetailRow(
                  label: 'Salvage Value',
                  value: currencyFormat.format(salvageValue),
                ),
                _DetailRow(
                  label: 'Accumulated Depr.',
                  value: currencyFormat.format(accumulatedDepr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Schedule',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...scheduleItems.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.$2,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.$3,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.$4,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Maintenance Tab ───────────────────────────────────────────────────────────
class _MaintenanceTab extends StatelessWidget {
  const _MaintenanceTab({required this.asset});
  final AssetLocal asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MaintenanceLocal>>(
            stream: context.read<MaintenanceService>().getMaintenanceStream(
              assetId: asset.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              final records = snapshot.data ?? [];
              if (records.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No maintenance records for this asset',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: records.length,
                separatorBuilder: (_, __) => Divider(
                  height: 32,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                itemBuilder: (context, i) {
                  final rec = records[i];
                  final status = rec.status;
                  final isCompleted = status.toLowerCase() == 'completed';
                  final statusColor = isCompleted
                      ? AppColors.success
                      : (status.toLowerCase() == 'scheduled'
                            ? AppColors.secondary
                            : AppColors.warning);

                  return Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.build_circle_rounded,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rec.type.toUpperCase(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat('dd-MM-yyyy').format(
                                DateTime.fromMillisecondsSinceEpoch(rec.dateMs),
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (rec.notes != null && rec.notes!.isNotEmpty)
                              Text(
                                rec.notes!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Schedule Maintenance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddMaintenanceDialog(asset: asset),
    );
  }
}

class _AddMaintenanceDialog extends StatefulWidget {
  const _AddMaintenanceDialog({required this.asset});
  final AssetLocal asset;

  @override
  State<_AddMaintenanceDialog> createState() => _AddMaintenanceDialogState();
}

class _AddMaintenanceDialogState extends State<_AddMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _costController = TextEditingController();
  String _type = 'preventive';
  String _status = 'scheduled';
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Maintenance'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['preventive', 'corrective', 'emergency', 'scheduled']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['scheduled', 'in_progress', 'completed']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Cost (LE)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('dd-MM-yyyy').format(_date)),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() async {
    final service = context.read<MaintenanceService>();
    final record = MaintenanceLocal(
      id: '',
      assetId: widget.asset.id,
      assetName: widget.asset.name,
      dateMs: _date.millisecondsSinceEpoch,
      type: _type,
      cost: double.tryParse(_costController.text) ?? 0.0,
      status: _status,
      notes: _noteController.text,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    final success = await service.addMaintenance(record);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}

// ── Documents Tab ─────────────────────────────────────────────────────────────
class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.asset});
  final AssetLocal asset;

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        if (!context.mounted) return;
        
        final filesService = context.read<FilesService>();
        await filesService.uploadFile(
          pickedFile, 
          fileName, 
          category: 'Asset Documents',
          assetId: asset.id,
        );
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filesService = context.watch<FilesService>();

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<FileItem>>(
            stream: filesService.getFilesStream(assetId: asset.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final docs = snapshot.data ?? [];
              
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No documents attached',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                separatorBuilder: (_, __) => Divider(
                  height: 32,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                itemBuilder: (_, i) {
                  final file = docs[i];
                  return Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getFileIcon(file.type), 
                          color: AppColors.primary, 
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              file.size,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => OpenFile.open(file.localPath),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: cs.error,
                          size: 20,
                        ),
                        onPressed: () => filesService.deleteFile(file.id, file.localPath),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _pickAndUpload(context),
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Upload Document'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Financial Info Tab ────────────────────────────────────────────────────────
class _FinancialInfoTab extends StatelessWidget {
  const _FinancialInfoTab({required this.asset});
  final AssetLocal asset;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'LE ',
      decimalDigits: 0,
      locale: 'en_US',
    );
    final totalCapitalized = asset.purchasePrice;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
            label: 'Original Cost',
            value: currencyFormat.format(asset.purchasePrice),
          ),
          const Divider(height: 32),
          _DetailRow(
            label: 'Total Capitalized',
            value: currencyFormat.format(totalCapitalized),
            valueColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Funding Source', value: asset.vendor ?? 'Not set'),
          _DetailRow(
            label: 'Reference',
            value: asset.id.split('-').first.toUpperCase(),
          ),
          _DetailRow(
            label: 'Updated At',
            value: DateFormat(
              'dd-MM-yyyy',
            ).format(DateTime.fromMillisecondsSinceEpoch(asset.updatedAtMs)),
          ),
        ],
      ),
    );
  }
}

// ── Location History Tab ───────────────────────────────────────────────────
class _LocationHistoryTab extends StatelessWidget {
  const _LocationHistoryTab({required this.asset});
  final AssetLocal asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final List<(String, String, String)> history = [
      if (asset.location != null && asset.location!.isNotEmpty)
        (
          asset.location!,
          DateFormat(
            'dd-MM-yyyy',
          ).format(DateTime.fromMillisecondsSinceEpoch(asset.updatedAtMs)),
          'Current',
        ),
    ];

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No location history available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: history.length,
      separatorBuilder: (_, __) =>
          Divider(height: 32, color: cs.outlineVariant.withValues(alpha: 0.3)),
      itemBuilder: (context, i) {
        final (location, date, tag) = history[i];
        final isCurrent = tag == 'Current';
        return Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    (isCurrent ? AppColors.primary : cs.surfaceContainerHighest)
                        .withValues(alpha: isCurrent ? 0.1 : 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: isCurrent ? AppColors.primary : cs.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Last seen: $date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (isCurrent ? AppColors.primary : cs.surfaceContainerHighest)
                        .withValues(alpha: isCurrent ? 0.15 : 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCurrent ? AppColors.primary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline Tab ───────────────────────────────────────────────────────────
class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.asset});
  final AssetLocal asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<AssetTimelineLocal>>(
            stream: context.read<TimelineService>().getTimelineStream(asset.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No history for this asset',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isLast = index == events.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  width: 4,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: cs.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatActionTitle(event.action),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy · HH:mm').format(event.timestamp),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                if (event.details != null && event.details!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _formatDetails(event.details!),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatActionTitle(String action) {
    if (action.isEmpty) return 'Unknown Action';
    return action[0].toUpperCase() + action.substring(1).toLowerCase();
  }

  String _formatDetails(Map<String, dynamic> details) {
    return details.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}
