import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../core/assets/asset_service.dart';
import '../../../core/sync/models/asset_local.dart';
import 'package:assets_management/shared/widgets/app_bottom_nav.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class _HardwareItem {
  const _HardwareItem({
    required this.deviceName,
    required this.assetId,
    required this.assignedTo,
    required this.status,
    required this.purchaseDate,
  });

  final String deviceName;
  final String assetId;
  final String? assignedTo;
  final String status; // 'Active' | 'Maintenance' | 'Retired'
  final String purchaseDate;
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ComputerHardwareListScreen extends StatefulWidget {
  const ComputerHardwareListScreen({super.key});

  @override
  State<ComputerHardwareListScreen> createState() =>
      _ComputerHardwareListScreenState();
}

class _ComputerHardwareListScreenState
    extends State<ComputerHardwareListScreen> {
  bool _searchActive = false;
  String _query = '';
  String _statusFilter = 'All';
  final _searchCtrl = TextEditingController();

  static const _filterOptions = ['All', 'Active', 'Maintenance', 'Retired'];

  late final Stream<List<AssetLocal>> _assetsStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _assetsStream = context.read<AssetService>().getAssetsByCategory(
      uid,
      'computer hardware',
    );
  }

  void _showFilterSheet() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Text(
                      'Filter by Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ..._filterOptions.map((opt) {
                final selected = opt == _statusFilter;
                return ListTile(
                  title: Text(
                    opt,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selected
                          ? AppColors.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() => _statusFilter = opt);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: _searchActive
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Search hardware…',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _searchActive ? Icons.close : Icons.search,
              color: AppColors.primary,
            ),
            onPressed: () => setState(() {
              _searchActive = !_searchActive;
              if (!_searchActive) {
                _query = '';
                _searchCtrl.clear();
              }
            }),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.primary.withValues(alpha: 0.2),
            height: 1.2,
          ),
        ),
      ),

      body: StreamBuilder<List<AssetLocal>>(
        stream: _assetsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allLocalAssets = snapshot.data ?? [];
          final mappedHardware = allLocalAssets.map((a) {
            final fallbackStatus =
                ['Active', 'Maintenance', 'Retired'].contains(a.status)
                ? a.status
                : 'Active';
            return _HardwareItem(
              deviceName: a.name,
              assetId: a.id.length > 8 ? a.id.substring(0, 8) : a.id,
              assignedTo: a.assignedTo,
              status: fallbackStatus,
              purchaseDate: a.purchaseDateMs != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      a.purchaseDateMs!,
                    ).toString().split(' ')[0]
                  : 'N/A',
            );
          }).toList();

          final q = _query.toLowerCase();
          final filtered = mappedHardware.where((h) {
            final matchesQuery =
                q.isEmpty ||
                h.deviceName.toLowerCase().contains(q) ||
                h.assetId.toLowerCase().contains(q) ||
                (h.assignedTo?.toLowerCase().contains(q) ?? false);
            final matchesStatus =
                _statusFilter == 'All' || h.status == _statusFilter;
            return matchesQuery && matchesStatus;
          }).toList();

          final activeCount = mappedHardware
              .where((h) => h.status == 'Active')
              .length;
          final maintenanceCount = mappedHardware
              .where((h) => h.status == 'Maintenance')
              .length;
          final retiredCount = mappedHardware
              .where((h) => h.status == 'Retired')
              .length;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header row ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Computer Hardware',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Stats row ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${mappedHardware.length}',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status breakdown',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _StatCell(
                                    value: '$activeCount',
                                    label: 'Active',
                                    theme: theme,
                                  ),
                                ),
                                Expanded(
                                  child: _StatCell(
                                    value: '$maintenanceCount',
                                    label: 'Maintenance',
                                    theme: theme,
                                  ),
                                ),
                                Expanded(
                                  child: _StatCell(
                                    value: '$retiredCount',
                                    label: 'Retired',
                                    theme: theme,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ── List header + filter ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Assets',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _showFilterSheet,
                        icon: Icon(
                          Icons.filter_list,
                          size: 18,
                          color: _statusFilter != 'All'
                              ? AppColors.primary
                              : cs.onSurface,
                        ),
                        label: Text(
                          _statusFilter != 'All' ? _statusFilter : 'Filters',
                          style: TextStyle(
                            color: _statusFilter != 'All'
                                ? AppColors.primary
                                : cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, indent: 20, endIndent: 20),

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'No items match your search.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...filtered.map((h) {
                    final asset = allLocalAssets.firstWhere(
                      (a) => a.id.contains(h.assetId) || a.name == h.deviceName,
                    );
                    return _HardwareListTile(
                      item: h,
                      asset: asset,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.computerHardwareDetail,
                        arguments: asset,
                      ),
                    );
                  }),

                const Divider(height: 1, indent: 20, endIndent: 20),

                if (filtered.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All hardware assets loaded.'),
                        ),
                      );
                    },
                    child: Center(
                      child: Text(
                        'Show more',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (FirebaseAuth.instance.currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('You must be logged in.')),
            );
            return;
          }
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.addAsset, arguments: 'computer hardware');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Hardware',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}

// ── Stat cell ────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.theme,
  });
  final String value;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── List tile ────────────────────────────────────────────────────────────────
class _HardwareListTile extends StatelessWidget {
  const _HardwareListTile({
    required this.item,
    required this.onTap,
    required this.asset,
  });
  final _HardwareItem item;
  final AssetLocal asset;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Maintenance':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.computer_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Name + details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.deviceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${item.assetId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (item.assignedTo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Assigned: ${item.assignedTo}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Status + date
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(item.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _statusColor(item.status),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.purchaseDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
