import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/assets/asset_service.dart';
import '../../../core/sync/models/asset_local.dart';
import 'package:assets_management/shared/widgets/app_bottom_nav.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class _FixedAssetItem {
  const _FixedAssetItem({
    required this.assetName,
    required this.assetCode,
    required this.category,
    required this.purchaseDate,
    required this.bookValue,
    required this.status,
  });

  final String assetName;
  final String assetCode;
  final String category; // 'Building' | 'Equipment' | 'Land' | 'Infrastructure'
  final String purchaseDate;
  final String bookValue;
  final String status; // 'Active' | 'Depreciating' | 'Disposed'
}

// ── Screen ────────────────────────────────────────────────────────────────────
class FixedAssetsListScreen extends StatefulWidget {
  const FixedAssetsListScreen({super.key});

  @override
  State<FixedAssetsListScreen> createState() => _FixedAssetsListScreenState();
}

class _FixedAssetsListScreenState extends State<FixedAssetsListScreen> {
  bool _searchActive = false;
  String _query = '';
  String _statusFilter = 'All';
  final _searchCtrl = TextEditingController();

  late final Stream<List<AssetLocal>> _assetsStream;

  static const _filterOptions = ['All', 'Active', 'Depreciating', 'Disposed'];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _assetsStream = context.read<AssetService>().getAssetsByCategory(
      uid,
      'fixed',
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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter by Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ..._filterOptions.map((opt) {
                final selected = opt == _statusFilter;
                return ListTile(
                  title: Text(
                    opt,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selected ? AppColors.primary : cs.onSurface,
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
                  hintText: 'Search fixed assets…',
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

          final localAssets = snapshot.data ?? [];
          final allAssets = localAssets.map((a) {
            final dateStr = a.purchaseDateMs != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    a.purchaseDateMs!,
                  ).toLocal().toString().split(' ')[0]
                : 'N/A';

            // Map status fallback
            final fallbackStatus =
                ['Active', 'Depreciating', 'Disposed'].contains(a.status)
                ? a.status
                : 'Active';

            return _FixedAssetItem(
              assetName: a.name,
              assetCode: a.id.length >= 8
                  ? a.id.substring(0, 8).toUpperCase()
                  : a.id,
              category: a.category,
              purchaseDate: dateStr,
              bookValue: 'LE ${a.currentValue.toStringAsFixed(0)}',
              status: fallbackStatus,
            );
          }).toList();

          final q = _query.toLowerCase();
          final filtered = allAssets.where((f) {
            final matchesQuery =
                q.isEmpty ||
                f.assetName.toLowerCase().contains(q) ||
                f.assetCode.toLowerCase().contains(q) ||
                f.category.toLowerCase().contains(q);
            final matchesStatus =
                _statusFilter == 'All' || f.status == _statusFilter;
            return matchesQuery && matchesStatus;
          }).toList();

          final activeCount = allAssets
              .where((f) => f.status == 'Active')
              .length;
          final depreciatingCount = allAssets
              .where((f) => f.status == 'Depreciating')
              .length;
          final disposedCount = allAssets
              .where((f) => f.status == 'Disposed')
              .length;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Fixed Assets',
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
                              '${allAssets.length}',
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
                                    value: '$depreciatingCount',
                                    label: 'Deprec.',
                                    theme: theme,
                                  ),
                                ),
                                Expanded(
                                  child: _StatCell(
                                    value: '$disposedCount',
                                    label: 'Disposed',
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
                  ...filtered.map((f) {
                    final asset = localAssets.firstWhere(
                      (a) =>
                          a.id.contains(f.assetCode) || a.name == f.assetName,
                    );
                    return _FixedAssetListTile(
                      item: f,
                      asset: asset,
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.fixedAssetDetail, arguments: asset),
                    );
                  }),

                const Divider(height: 1, indent: 20, endIndent: 20),

                if (filtered.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All fixed assets loaded.'),
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

                const SizedBox(height: 80),
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
          ).pushNamed(AppRoutes.addAsset, arguments: 'fixed');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Fixed Asset',
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
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── List tile ────────────────────────────────────────────────────────────────
class _FixedAssetListTile extends StatelessWidget {
  const _FixedAssetListTile({
    required this.item,
    required this.onTap,
    required this.asset,
  });
  final _FixedAssetItem item;
  final AssetLocal asset;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Depreciating':
        return AppColors.secondary;
      default:
        return AppColors.danger;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Building':
        return Icons.business_rounded;
      case 'Land':
        return Icons.landscape_rounded;
      case 'Infrastructure':
        return Icons.account_tree_rounded;
      default:
        return Icons.precision_manufacturing_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              child: Icon(
                _categoryIcon(item.category),
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
                    item.assetName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Code: ${item.assetCode} • ${item.category}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Value: ${item.bookValue}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
