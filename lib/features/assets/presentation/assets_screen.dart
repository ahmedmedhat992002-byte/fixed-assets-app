import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/analytics/models/analytics_data.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/data_utils.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/search/global_search_delegate.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  bool _showAllWarehouses = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
            onPressed: () {
              showSearch(context: context, delegate: GlobalSearchDelegate());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.primary, height: 1.2),
        ),
      ),
      body: StreamBuilder<AnalyticsData>(
        stream: analyticsService.getAnalyticsDataStream(
          auth.firebaseUser?.uid ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          final data = snapshot.data ?? AnalyticsData.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, data),
                const SizedBox(height: 32),
                Text(
                  'Browse by Category',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildCategoryGrid(context, data),
                const SizedBox(height: 32),

                // ── Warehouses ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Warehouses',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.warehouses);
                      },
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(height: 1),
                const SizedBox(height: 12),

                if (data.analysisByWarehouse.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No warehouse data available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else ...[
                  ..._getWarehouseItems(data).map((entry) {
                    final warehouseName = entry.key;
                    final catCounts = entry.value;

                    final displayItems = [
                      _WarehouseItem(
                        label: 'Machines',
                        count: catCounts['Machinery'] ?? 0,
                      ),
                      _WarehouseItem(
                        label: 'Furniture',
                        count: catCounts['Furniture'] ?? 0,
                      ),
                      _WarehouseItem(
                        label: 'Vehicles',
                        count: catCounts['Vehicles'] ?? 0,
                      ),
                      _WarehouseItem(
                        label: 'C. Hardware',
                        count: catCounts['Computer hardware'] ?? 0,
                      ),
                    ];

                    return Column(
                      children: [
                        _WarehouseCard(
                          name: warehouseName,
                          items: displayItems,
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
                  if (data.analysisByWarehouse.length > 2)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllWarehouses = !_showAllWarehouses;
                          });
                        },
                        child: Text(
                          _showAllWarehouses ? 'Show less' : 'Show more',
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 28),

                // ── Valuation ─────────────────────────────────────────
                Text(
                  'Valuation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _ValueCard(
                  label: 'Value on registration',
                  value: DataUtils.formatCurrency(data.totalRegisteredValue),
                ),
                const SizedBox(height: 12),
                _ValueCard(
                  label: 'Current value',
                  value: DataUtils.formatCurrency(data.currentValue),
                  isPositive: data.currentValue >= data.totalRegisteredValue,
                ),
                const SizedBox(height: 12),
                _ValueCard(
                  label: 'Projected increase',
                  value: DataUtils.formatCurrency(data.projectedIncrease),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.analytics);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Full Analytics',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Iterable<MapEntry<String, Map<String, int>>> _getWarehouseItems(
    AnalyticsData data,
  ) {
    if (_showAllWarehouses) return data.analysisByWarehouse.entries;
    return data.analysisByWarehouse.entries.take(2);
  }

  Widget _buildHeader(BuildContext context, AnalyticsData data) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assets',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'LE ${DataUtils.formatCurrency(data.currentValue)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            if (data.projectedIncrease != 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+ ${((data.projectedIncrease / (data.currentValue == 0 ? 1 : data.currentValue)) * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        Text(
          'Total value',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _StatItem(
              value: data.totalAssetsCount.toString(),
              label: 'Total assets',
            ),
            const SizedBox(width: 32),
            _StatItem(
              value: data.industriesCount.toString(),
              label: 'Industries',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _AssetBox(
                id: 'Highest',
                value: data.highestValueAsset,
                label: 'Highest value asset',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AssetBox(
                id: 'Lowest',
                value: data.lowestValueAsset,
                label: 'Lowest value asset',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, AnalyticsData data) {
    final counts = data.analysisByCategoryCount;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _CategoryCard(
          icon: Icons.directions_car_rounded,
          label: 'Vehicles',
          count: counts['Vehicles'] ?? 0,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.vehiclesList),
        ),
        _CategoryCard(
          icon: Icons.precision_manufacturing_rounded,
          label: 'Machinery',
          count: counts['Machinery'] ?? 0,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.machineryList),
        ),
        _CategoryCard(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Intangible',
          count: counts['Intangible'] ?? 0,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.intangibleAssets),
        ),
        _CategoryCard(
          icon: Icons.computer_rounded,
          label: 'Computer Hardware',
          count: counts['Computer hardware'] ?? 0,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.computerHardwareList),
        ),
        _CategoryCard(
          icon: Icons.grid_view_rounded,
          label: 'Computer Software',
          count: counts['Computer software'] ?? 0,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.computerSoftwareList),
        ),
        _CategoryCard(
          icon: Icons.chair_rounded,
          label: 'Furniture',
          count: counts['Furniture'] ?? 0,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.furnitureList),
        ),
        _CategoryCard(
          icon: Icons.business_rounded,
          label: 'Fixed Assets',
          count: counts['Fixed assets'] ?? 0,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.fixedAssetsList),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AssetBox extends StatelessWidget {
  const _AssetBox({required this.id, required this.value, required this.label});
  final String id;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            id,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}

class _WarehouseItem extends StatelessWidget {
  const _WarehouseItem({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$count items',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  const _WarehouseCard({required this.name, required this.items});
  final String name;
  final List<_WarehouseItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3,
          children: items,
        ),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.label, required this.value, this.isPositive});

  final String label;
  final String value;
  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            children: [
              if (isPositive != null)
                Icon(
                  isPositive! ? Icons.trending_up : Icons.trending_down,
                  color: isPositive! ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
              if (isPositive != null) const SizedBox(width: 8),
              Text(
                'LE $value',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$count items',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
