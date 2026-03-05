import 'dart:math' as math;

import 'package:assets_management/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/dashboard/dashboard_service.dart';
import '../../../core/assets/asset_service.dart';
import '../../../../core/search/global_search_delegate.dart';
import '../../../core/dashboard/models/dashboard_stats.dart';
import '../../../core/dashboard/models/transaction_item.dart';
import '../../../core/sync/models/asset_local.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onNavigateToIntangible,
    this.onOpenDrawer,
    this.isDrawerVisible = false,
  });

  final VoidCallback? onNavigateToIntangible;
  final VoidCallback? onOpenDrawer;
  final bool isDrawerVisible;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Stream<DashboardStats> _statsStream;
  late final Stream<List<TransactionItem>> _transactionsStream;

  String _selectedTab = 'Recently added';
  String _statusFilter = 'All';
  bool _showAllRecentlyAdded = false;
  bool _showAllTransactions = false;

  static const _filterOptions = [
    'All',
    'Active',
    'Maintenance',
    'Malfunctioned',
    'Disposed',
  ];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final dashboardService = context.read<DashboardService>();

    _statsStream = dashboardService.getDashboardStatsStream(uid);
    _transactionsStream = dashboardService.getLatestTransactionsStream(uid);
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

  Stream<List<AssetLocal>> _getAssetsStreamForTab(String tabName) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final dashboardService = context.read<DashboardService>();

    switch (tabName) {
      case 'Recently added':
        return dashboardService.getRecentlyAddedStream(uid);
      case 'Intangible':
        return dashboardService.getAssetsByCategoryStream(uid, 'intangible');
      case 'Machinery':
        return dashboardService.getAssetsByCategoryStream(uid, 'machinery');
      case 'Vehicles':
        return dashboardService.getAssetsByCategoryStream(uid, 'vehicles');
      case 'Fixed assets':
        return dashboardService.getAssetsByCategoryStream(uid, 'fixed assets');
      default:
        return dashboardService.getRecentlyAddedStream(uid);
    }
  }

  void _openSearch(BuildContext context) {
    showSearch(context: context, delegate: GlobalSearchDelegate());
  }

  Future<void> _showDeleteAllConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Assets'),
        content: const Text(
          'Are you sure you want to delete all assets at once? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final assetService = context.read<AssetService>();
      final success = await assetService.deleteAllAssets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Successfully deleted all assets'
                  : (assetService.lastError ?? 'Failed to delete assets'),
            ),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAllTransactionsConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Transactions'),
        content: const Text(
          'Are you sure you want to delete all transactions at once? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final success = await context
          .read<DashboardService>()
          .deleteAllTransactions(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Successfully deleted all transactions'
                  : 'Failed to delete transactions',
            ),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final curf = NumberFormat.currency(symbol: 'LE ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: theme.colorScheme.primary),
          onPressed: () => widget.onOpenDrawer?.call(),
        ),
        title: Image.asset(
          'assets/logo_new.jpeg',
          height: 60,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'World Assets',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.primary, thickness: 1.2, height: 12),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.dashboardOverview,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),

            // ── Overview Section (Stats) ──
            StreamBuilder<DashboardStats>(
              stream: _statsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading stats');
                }

                final stats = snapshot.data ?? DashboardStats.empty();

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OverviewChart(
                          stats: stats,
                        ), // Passes stats to calculate animated segments
                        const SizedBox(width: 28),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LegendItem(
                                label: 'Total Assets',
                                value: curf.format(stats.totalValue),
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 16),
                              _LegendItem(
                                label: 'Depreciation',
                                value: curf.format(stats.totalDepreciation),
                                color: AppColors.secondary,
                              ),
                              const SizedBox(height: 16),
                              _LegendItem(
                                label: 'Net Assets Value',
                                value: curf.format(stats.netValue),
                                color: AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _LegendItem(
                            label: 'In Maint.',
                            value: '${stats.assetsInMaintenance}',
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _LegendItem(
                            label: 'New',
                            value: '${stats.newAssetsThisPeriod}',
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _LegendItem(
                            label: 'Disposed',
                            value: '${stats.disposedAssets}',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.navAssets,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _showDeleteAllConfirmation,
                        child: Text(
                          'Delete All',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.assets),
                        child: Text(
                          AppLocalizations.of(context)!.dashboardViewAll,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Assets List by Category ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  _AssetTabs(
                    selectedTab: _selectedTab,
                    statusFilter: _statusFilter,
                    onTabSelected: (tab) {
                      setState(() {
                        _selectedTab = tab;
                      });
                    },
                    onFilterPressed: _showFilterSheet,
                    onNavigateToIntangible: widget.onNavigateToIntangible,
                  ),
                  const Divider(height: 1),
                  StreamBuilder<List<AssetLocal>>(
                    stream: _getAssetsStreamForTab(_selectedTab),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: const Center(child: SizedBox.shrink()),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text('Failed to load assets.')),
                        );
                      }

                      final allAssets = snapshot.data ?? [];

                      // Apply Status Filter locally
                      final filteredAssets = _statusFilter == 'All'
                          ? allAssets
                          : allAssets
                                .where(
                                  (a) =>
                                      a.status.toLowerCase() ==
                                      _statusFilter.toLowerCase(),
                                )
                                .toList();

                      if (filteredAssets.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: Text('No assets found.')),
                        );
                      }

                      final assetsToShow = _showAllRecentlyAdded
                          ? filteredAssets
                          : filteredAssets.take(3).toList();

                      return Column(
                        children: [
                          ...assetsToShow.map(
                            (asset) => _AssetTile(asset: asset, curf: curf),
                          ),
                          if (filteredAssets.length > 3)
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showAllRecentlyAdded =
                                        !_showAllRecentlyAdded;
                                  });
                                },
                                child: Text(
                                  _showAllRecentlyAdded
                                      ? 'Show less'
                                      : 'Show more',
                                ),
                              ),
                            ),
                          if (filteredAssets.length > 3)
                            const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.dashboardLatestTransactions,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _showDeleteAllTransactionsConfirmation,
                        child: Text(
                          'Delete All',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.transactions),
                        child: Text(
                          AppLocalizations.of(context)!.dashboardViewAll,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Latest Transactions ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: StreamBuilder<List<TransactionItem>>(
                stream: _transactionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: const Center(child: SizedBox.shrink()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('Failed to load transactions.'),
                      ),
                    );
                  }

                  final allTransactions = snapshot.data ?? [];
                  if (allTransactions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No recent transactions.')),
                    );
                  }

                  final transactionsToShow = _showAllTransactions
                      ? allTransactions
                      : allTransactions.take(3).toList();

                  return Column(
                    children: [
                      ...transactionsToShow.map(
                        (transaction) => _TransactionTile(
                          transaction: transaction,
                          curf: curf,
                        ),
                      ),
                      if (allTransactions.length > 3)
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _showAllTransactions = !_showAllTransactions;
                              });
                            },
                            child: Text(
                              _showAllTransactions ? 'Show less' : 'Show more',
                            ),
                          ),
                        ),
                      if (allTransactions.length > 3) const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'fab_dashboard_qr',
        backgroundColor: AppColors.primary,
        tooltip: AppLocalizations.of(context)!.navScanQr,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.qrScan),
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
    );
  }
}

class _OverviewRing extends StatelessWidget {
  const _OverviewRing({
    required this.color,
    required this.value,
    required this.thickness,
    this.trackColor,
    this.startAngle = -math.pi / 2,
    this.diameter = 140,
  });

  final Color color;
  final double value;
  final double thickness;
  final Color? trackColor;
  final double startAngle;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: diameter,
      width: diameter,
      child: CustomPaint(
        painter: _RingPainter(
          color: color,
          value: value,
          strokeWidth: thickness,
          trackColor: trackColor,
          startAngle: startAngle,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.color,
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.startAngle,
  });

  final Color color;
  final double value;
  final double strokeWidth;
  final Color? trackColor;
  final double startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    if (trackColor != null) {
      final trackPaint = Paint()
        ..color = trackColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, trackPaint);
    }

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }

  @override
  bool shouldRebuildSemantics(covariant _RingPainter oldDelegate) => false;
}

class _OverviewChart extends StatefulWidget {
  final DashboardStats stats;

  const _OverviewChart({required this.stats});

  @override
  State<_OverviewChart> createState() => _OverviewChartState();
}

class _OverviewChartState extends State<_OverviewChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _OverviewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats.totalValue != widget.stats.totalValue) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const baseDiameter = 152.0;
    const shrinkStep = 22.0;

    // Dynamic calculation: If total is 0, show tiny segments or empty
    final total = widget.stats.totalValue > 0 ? widget.stats.totalValue : 1.0;
    final netPct = (widget.stats.netValue / total).clamp(0.0, 1.0);
    final depPct = (widget.stats.totalDepreciation / total).clamp(0.0, 1.0);

    final segments = [
      _ChartSegment(
        color: AppColors.primary,
        trackColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        value: widget.stats.totalValue > 0
            ? 0.95
            : 0.0, // Outer ring represents total assets visually
        startAngle: -2.5,
        thickness: 18,
      ),
      _ChartSegment(
        color: AppColors.secondary,
        trackColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        value: depPct,
        startAngle: -2.05,
        thickness: 14,
      ),
      _ChartSegment(
        color: AppColors.success,
        trackColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        value: netPct,
        startAngle: -1.62,
        thickness: 12,
      ),
    ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: baseDiameter,
          width: baseDiameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _OverviewRing(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                value: 1,
                thickness: 20,
                trackColor: theme.colorScheme.surfaceContainerHighest,
                diameter: baseDiameter,
              ),
              for (var i = 0; i < segments.length; i++)
                _OverviewRing(
                  color: segments[i].color,
                  value: segments[i].value * _animation.value,
                  thickness: segments[i].thickness,
                  trackColor: segments[i].trackColor,
                  startAngle: segments[i].startAngle,
                  diameter: baseDiameter - (i + 1) * shrinkStep,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartSegment {
  const _ChartSegment({
    required this.color,
    required this.trackColor,
    required this.value,
    required this.startAngle,
    required this.thickness,
  });

  final Color color;
  final Color trackColor;
  final double value;
  final double startAngle;
  final double thickness;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssetTabs extends StatelessWidget {
  const _AssetTabs({
    required this.selectedTab,
    required this.statusFilter,
    required this.onTabSelected,
    required this.onFilterPressed,
    this.onNavigateToIntangible,
  });

  final String selectedTab;
  final String statusFilter;
  final ValueChanged<String> onTabSelected;
  final VoidCallback onFilterPressed;
  final VoidCallback? onNavigateToIntangible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isFilterActive = statusFilter != 'All';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        height: 45,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _TabChip(
              label: 'Recently added',
              selected: selectedTab == 'Recently added',
              onTap: () => onTabSelected('Recently added'),
            ),
            const SizedBox(width: 8),
            _TabChip(
              label: 'Intangible',
              selected: selectedTab == 'Intangible',
              onTap: () {
                onTabSelected('Intangible');
              },
            ),
            const SizedBox(width: 8),
            _TabChip(
              label: 'Machinery',
              selected: selectedTab == 'Machinery',
              onTap: () => onTabSelected('Machinery'),
            ),
            const SizedBox(width: 8),
            _TabChip(
              label: 'Vehicles',
              selected: selectedTab == 'Vehicles',
              onTap: () => onTabSelected('Vehicles'),
            ),
            const SizedBox(width: 8),
            _TabChip(
              label: 'Fixed assets',
              selected: selectedTab == 'Fixed assets',
              onTap: () => onTabSelected('Fixed assets'),
            ),

            const SizedBox(width: 12),
            const VerticalDivider(width: 1, indent: 8, endIndent: 8),
            const SizedBox(width: 12),

            // Styled Filter Button
            InkWell(
              onTap: onFilterPressed,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isFilterActive ? AppColors.primary : cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFilterActive
                        ? AppColors.primary
                        : cs.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFilterActive ? statusFilter : 'Filter',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isFilterActive
                            ? Colors.white
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                      color: isFilterActive ? Colors.white : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? theme.colorScheme.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.asset, required this.curf});

  final AssetLocal asset;
  final NumberFormat curf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateStr = (asset.updatedAtMs > 0)
        ? DateFormat.yMMMd().format(
            DateTime.fromMillisecondsSinceEpoch(asset.updatedAtMs),
          )
        : 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            String route;
            switch (asset.category.toLowerCase()) {
              case 'machinery':
                route = AppRoutes.machineryDetail;
                break;
              case 'vehicles':
                route = AppRoutes.vehicleDetail;
                break;
              case 'furniture':
                route = AppRoutes.furnitureDetail;
                break;
              case 'computer hardware':
                route = AppRoutes.computerHardwareDetail;
                break;
              case 'computer software':
                route = AppRoutes.computerSoftwareDetail;
                break;
              case 'fixed':
              case 'fixed asset':
                route = AppRoutes.fixedAssetDetail;
                break;
              default:
                route = AppRoutes.machineryDetail; // Fallback
            }
            Navigator.of(context).pushNamed(route, arguments: asset);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon styling
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & Value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          children: [
                            const TextSpan(text: 'Valued at: '),
                            TextSpan(
                              text: curf.format(
                                asset.currentValue > 0
                                    ? asset.currentValue
                                    : asset.purchasePrice,
                              ),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Category & Date Action Row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        asset.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),

                // Deletion Icon
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Asset'),
                          content: const Text(
                            'Are you sure you want to delete this asset?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        final service = context.read<AssetService>();
                        final success = await service.deleteAsset(asset.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Asset deleted successfully'
                                    : (service.lastError ??
                                          'Failed to delete asset'),
                              ),
                              backgroundColor: success
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.curf});

  final TransactionItem transaction;
  final NumberFormat curf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _getTypeColor(transaction.type);

    final dateStr = (transaction.date != null)
        ? DateFormat('MMM d, y').format(transaction.date!.toDate())
        : 'Unknown';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getTypeIcon(transaction.type),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Amount
              Text(
                curf.format(transaction.amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return AppColors.primary;
      case 'disposal':
        return AppColors.danger;
      case 'maintenance':
        return const Color(0xFFFF9800);
      case 'depreciation':
        return AppColors.secondary;
      default:
        return AppColors.success;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return Icons.shopping_bag_rounded;
      case 'disposal':
        return Icons.auto_delete_rounded;
      case 'maintenance':
        return Icons.handyman_rounded;
      case 'depreciation':
        return Icons.trending_down_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
