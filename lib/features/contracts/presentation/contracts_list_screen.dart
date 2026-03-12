import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/search/global_search_delegate.dart';
import '../../../core/contracts/contract_service.dart';
import '../../../core/contracts/models/contract_model.dart';

class ContractsListScreen extends StatefulWidget {
  const ContractsListScreen({super.key});

  @override
  State<ContractsListScreen> createState() => _ContractsListScreenState();
}

class _ContractsListScreenState extends State<ContractsListScreen> {
  String _statusFilter =
      'All'; // _searchActive, _query, _searchCtrl removed as per instruction

  late final Stream<List<ContractModel>> _contractsStream;

  static const _filterOptions = [
    'All',
    'Active',
    'Pending',
    'Expired',
    'Expiring Soon',
    'Terminated',
  ];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _contractsStream = context.read<ContractService>().getContractsStream(uid);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Contracts',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () {
              showSearch(context: context, delegate: GlobalSearchDelegate());
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              child: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
            ),
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

      body: StreamBuilder<List<ContractModel>>(
        stream: _contractsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final contracts = snapshot.data ?? [];
          final now = DateTime.now();

          // Compute dynamic statuses
          final mappedContracts = contracts.map((c) {
            final endDate = DateTime.fromMillisecondsSinceEpoch(c.endDateMs);
            String computedStatus = c.status;
            bool isExpiringSoon = false;

            if (endDate.isBefore(now)) {
              computedStatus = 'Expired';
            } else if (endDate.difference(now).inDays <= 30 &&
                c.status == 'Active') {
              isExpiringSoon = true;
            }

            return _ContractUIItem(
              model: c,
              computedStatus: computedStatus,
              isExpiringSoon: isExpiringSoon,
            );
          }).toList();

          final filteredContracts = mappedContracts.where((c) {
            if (_statusFilter == 'All') return true;
            if (_statusFilter == 'Expiring Soon') return c.isExpiringSoon;
            return c.computedStatus == _statusFilter;
          }).toList();

          final activeCount = mappedContracts
              .where((c) => c.computedStatus == 'Active')
              .length;
          final expiringCount = mappedContracts
              .where((c) => c.isExpiringSoon)
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
                        'All Contracts',
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
                              '${mappedContracts.length}',
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
                              'Key Insights',
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
                                    valueColor: AppColors.success,
                                  ),
                                ),
                                Expanded(
                                  child: _StatCell(
                                    value: '$expiringCount',
                                    label: 'Expiring Soon',
                                    theme: theme,
                                    valueColor: AppColors.danger,
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
                        'Contracts List',
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

                if (filteredContracts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'No items match your filter settings.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredContracts.map(
                    (c) => _ContractListTile(
                      item: c,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.contractDetail,
                        arguments: c.model.title,
                      ),
                    ),
                  ),

                const Divider(height: 1, indent: 20, endIndent: 20),

                TextButton(
                  onPressed: () {},
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
              SnackBar(
                content: const Text('You must be logged in to add a contract.'),
              ),
            );
            return;
          }
          Navigator.of(context).pushNamed(AppRoutes.addContract);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Contract',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── UI Intermediary ────────────────────────────────────────────────────────
class _ContractUIItem {
  final ContractModel model;
  final String computedStatus;
  final bool isExpiringSoon;

  _ContractUIItem({
    required this.model,
    required this.computedStatus,
    required this.isExpiringSoon,
  });
}

// ── Stat cell ────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.theme,
    this.valueColor,
  });
  final String value;
  final String label;
  final ThemeData theme;
  final Color? valueColor;

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
            color: valueColor ?? AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── List tile ────────────────────────────────────────────────────────────────
class _ContractListTile extends StatelessWidget {
  const _ContractListTile({required this.item, required this.onTap});
  final _ContractUIItem item;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Pending':
        return AppColors.secondary;
      case 'Terminated':
      case 'Expired':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statColor = _statusColor(item.computedStatus);

    final endDateStr = DateTime.fromMillisecondsSinceEpoch(
      item.model.endDateMs,
    ).toString().split(' ')[0];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon avatar
            Badge(
              isLabelVisible: item.isExpiringSoon,
              label: Icon(
                Icons.warning_amber_rounded,
                size: 10,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              backgroundColor: AppColors.danger,
              offset: const Offset(4, -4),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.model.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.model.contractNumber.length > 8 ? item.model.contractNumber.substring(0, 8) : item.model.contractNumber} • ${item.model.vendor}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Value: ${item.model.currency} ${item.model.value}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status + Date
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
                      color: statColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.computedStatus,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statColor,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'End: $endDateStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.isExpiringSoon
                          ? AppColors.danger
                          : cs.onSurfaceVariant,
                      fontWeight: item.isExpiringSoon
                          ? FontWeight.w700
                          : FontWeight.normal,
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
