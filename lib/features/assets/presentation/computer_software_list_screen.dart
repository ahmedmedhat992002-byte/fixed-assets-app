import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../core/assets/asset_service.dart';
import '../../../core/sync/models/asset_local.dart';
import 'package:assets_management/shared/widgets/app_bottom_nav.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class _SoftwareItem {
  const _SoftwareItem({
    required this.softwareName,
    required this.assetId,
    required this.licenseType,
    required this.licenseKey,
    required this.assignedTo,
    required this.expiryDate,
    required this.status,
  });

  final String softwareName;
  final String assetId;
  final String licenseType; // 'Subscription' | 'Perpetual'
  final String licenseKey;
  final String? assignedTo;
  final String expiryDate;
  final String status; // 'Active' | 'Expired' | 'Suspended'
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ComputerSoftwareListScreen extends StatefulWidget {
  const ComputerSoftwareListScreen({super.key});

  @override
  State<ComputerSoftwareListScreen> createState() =>
      _ComputerSoftwareListScreenState();
}

class _ComputerSoftwareListScreenState
    extends State<ComputerSoftwareListScreen> {
  bool _searchActive = false;
  String _query = '';
  String _statusFilter = 'All';
  final _searchCtrl = TextEditingController();

  static const _filterOptions = ['All', 'Active', 'Expired', 'Suspended'];
  static const _licenseFilterOptions = [
    'All Types',
    'Subscription',
    'Perpetual',
  ];
  String _licenseFilter = 'All Types';

  late final Stream<List<AssetLocal>> _assetsStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _assetsStream = context.read<AssetService>().getAssetsByCategory(
      uid,
      'computer software',
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
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter by License',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ..._licenseFilterOptions.map((opt) {
                final selected = opt == _licenseFilter;
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
                    setState(() => _licenseFilter = opt);
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

  bool get _hasFilter =>
      _statusFilter != 'All' || _licenseFilter != 'All Types';

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
                  hintText: 'Search software…',
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
          final mappedSoftware = allLocalAssets.map((a) {
            final fallbackStatus =
                ['Active', 'Expired', 'Suspended'].contains(a.status)
                ? a.status
                : 'Active';
            return _SoftwareItem(
              softwareName: a.name,
              assetId: a.id.length > 8 ? a.id.substring(0, 8) : a.id,
              licenseType: 'Subscription',
              licenseKey: '****-****-****',
              assignedTo: a.assignedTo,
              expiryDate: 'N/A',
              status: fallbackStatus,
            );
          }).toList();

          final q = _query.toLowerCase();
          final filtered = mappedSoftware.where((s) {
            final matchesQuery =
                q.isEmpty ||
                s.softwareName.toLowerCase().contains(q) ||
                s.assetId.toLowerCase().contains(q) ||
                (s.assignedTo?.toLowerCase().contains(q) ?? false);
            final matchesStatus =
                _statusFilter == 'All' || s.status == _statusFilter;
            final matchesLicense =
                _licenseFilter == 'All Types' ||
                s.licenseType == _licenseFilter;
            return matchesQuery && matchesStatus && matchesLicense;
          }).toList();

          final activeCount = mappedSoftware
              .where((s) => s.status == 'Active')
              .length;
          final expiredCount = mappedSoftware
              .where((s) => s.status == 'Expired')
              .length;
          final suspendedCount = mappedSoftware
              .where((s) => s.status == 'Suspended')
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
                        'Computer Software',
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
                              '${mappedSoftware.length}',
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
                                    value: '$expiredCount',
                                    label: 'Expired',
                                    theme: theme,
                                  ),
                                ),
                                Expanded(
                                  child: _StatCell(
                                    value: '$suspendedCount',
                                    label: 'Suspended',
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
                        'Licenses',
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
                          color: _hasFilter ? AppColors.primary : cs.onSurface,
                        ),
                        label: Text(
                          _hasFilter ? 'Filtered' : 'Filters',
                          style: TextStyle(
                            color: _hasFilter
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
                  ...filtered.map((s) {
                    final asset = allLocalAssets.firstWhere(
                      (a) =>
                          a.id.contains(s.assetId) || a.name == s.softwareName,
                    );
                    return _SoftwareListTile(
                      item: s,
                      asset: asset,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.computerSoftwareDetail,
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
                          content: Text('All software assets loaded.'),
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
          ).pushNamed(AppRoutes.addAsset, arguments: 'computer software');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Software',
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
class _SoftwareListTile extends StatelessWidget {
  const _SoftwareListTile({
    required this.item,
    required this.onTap,
    required this.asset,
  });
  final _SoftwareItem item;
  final AssetLocal asset;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Expired':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  IconData _licenseIcon(String licenseType) {
    return licenseType == 'Perpetual'
        ? Icons.all_inclusive_rounded
        : Icons.autorenew_rounded;
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
                _licenseIcon(item.licenseType),
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Name + details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.softwareName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.licenseType} · ${item.assetId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (item.assignedTo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.assignedTo!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Status + expiry
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
                    item.expiryDate == 'N/A'
                        ? 'Perpetual'
                        : 'Exp: ${item.expiryDate}',
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
