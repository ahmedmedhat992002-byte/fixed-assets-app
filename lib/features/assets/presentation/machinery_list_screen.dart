import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/assets/asset_service.dart';
import '../../../core/sync/models/asset_local.dart';
import 'package:assets_management/shared/widgets/app_bottom_nav.dart';

class _MachineItem {
  const _MachineItem({
    required this.name,
    required this.type,
    required this.value,
    required this.status,
  });

  final String name;
  final String type;
  final String value;
  final String status;
}

class MachineryListScreen extends StatefulWidget {
  const MachineryListScreen({super.key});

  @override
  State<MachineryListScreen> createState() => _MachineryListScreenState();
}

class _MachineryListScreenState extends State<MachineryListScreen> {
  bool _searchActive = false;
  String _query = '';
  String _statusFilter = 'All';
  final _searchCtrl = TextEditingController();
  static const _filterOptions = [
    'All',
    'Active',
    'Maintenance',
    'Malfunctioned',
  ];

  late final Stream<List<AssetLocal>> _assetsStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _assetsStream = context.read<AssetService>().getAssetsByCategory(
      uid,
      'machinery',
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return Container(
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
        );
      },
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
                decoration: const InputDecoration(
                  hintText: 'Search machinery…',
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
          child: Container(color: AppColors.primary, height: 1.2),
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

          // Determine items mapped to _MachineItem (we just map all assets for now, or filter by category if needed)
          // To ensure the new asset appears (especially if category wasn't set to "Machinery"), we map all or filter.
          // Since it's MachineryListScreen, we should ideally filter, but let's just show assets that have "Machinery"
          // Or we show all of them if the user doesn't have strict category selection yet.
          // We will filter by category 'Machinery' but fallback to showing all if none exist to avoid empty states initially.

          Iterable<AssetLocal> targetAssets = allLocalAssets;

          // Actually, let's map them properly:
          final mappedMachines = targetAssets.map((a) {
            final fallbackStatus =
                ['Active', 'Maintenance', 'Malfunctioned'].contains(a.status)
                ? a.status
                : 'Active';
            return _MachineItem(
              name: a.name,
              type: a.category,
              value: 'KES ${a.currentValue.toStringAsFixed(0)}',
              status: fallbackStatus,
            );
          }).toList();

          final q = _query.toLowerCase();
          final filtered = mappedMachines.where((m) {
            final matchesQuery =
                q.isEmpty ||
                m.name.toLowerCase().contains(q) ||
                m.type.toLowerCase().contains(q);
            final matchesStatus =
                _statusFilter == 'All' || m.status == _statusFilter;
            return matchesQuery && matchesStatus;
          }).toList();

          double totalValue = targetAssets.fold(
            0.0,
            (sum, item) => sum + item.currentValue,
          );
          String highestCategory = mappedMachines.isNotEmpty
              ? mappedMachines.first.type
              : 'N/A';

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Machinery',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total machines',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${mappedMachines.length}',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'KES ${totalValue.toStringAsFixed(0)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Total value',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Highest value',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.amber.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            highestCategory,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Category',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

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
                              : AppColors.textPrimary,
                        ),
                        label: Text(
                          _statusFilter != 'All' ? _statusFilter : 'Filters',
                          style: TextStyle(
                            color: _statusFilter != 'All'
                                ? AppColors.primary
                                : AppColors.textPrimary,
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
                        'No assets found.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...filtered.map((m) {
                    final asset = targetAssets.firstWhere(
                      (a) => a.name == m.name,
                    );
                    return _MachineListTile(machine: m, asset: asset);
                  }),

                const Divider(height: 1, indent: 20, endIndent: 20),

                if (filtered.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All machinery assets loaded.'),
                        ),
                      );
                    },
                    child: Center(
                      child: Text(
                        'Show more',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
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
          ).pushNamed(AppRoutes.addAsset, arguments: 'machinery');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Machinery',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}

class _MachineListTile extends StatelessWidget {
  const _MachineListTile({required this.machine, required this.asset});
  final _MachineItem machine;
  final AssetLocal asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).pushNamed(AppRoutes.machineryDetail, arguments: asset);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    machine.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Valued at: ${machine.value}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    machine.type,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    machine.status,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: machine.status == 'Active'
                          ? AppColors.success
                          : AppColors.danger,
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
