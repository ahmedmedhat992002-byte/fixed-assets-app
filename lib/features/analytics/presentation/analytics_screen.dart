import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:assets_management/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/search/global_search_delegate.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/analytics/models/analytics_data.dart';
import 'package:intl/intl.dart';

/// Full Analytics screen matching the design screenshot.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    this.onOpenDrawer,
    this.isDrawerVisible = false,
  });

  final VoidCallback? onOpenDrawer;
  final bool isDrawerVisible;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'All';
  bool _showAllCategories = false;

  static const _periods = ['Today', 'This Week', 'All'];
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () {
              showSearch(context: context, delegate: GlobalSearchDelegate());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          final user = authService.firebaseUser;
          if (user == null) {
            return const Center(child: Text('Please login to view analytics'));
          }

          return StreamBuilder<AnalyticsData>(
            stream: context.read<AnalyticsService>().getAnalyticsDataStream(
              user.uid,
              period: _period,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final data = snapshot.data ?? AnalyticsData.empty();

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    AppLocalizations.of(context)!.analyticsTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Period filter tabs
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.primaryLight,
                          width: 2,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _periods.map((p) {
                          final active = p == _period;
                          return GestureDetector(
                            onTap: () => setState(() => _period = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primaryLight
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: active
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _AnalyticsValuesGrid(data: data),
                  const SizedBox(height: 24),
                  _MultiLineChart(data: data),
                  const SizedBox(height: 28),
                  _AnalysisSection(
                    data: data,
                    showAll: _showAllCategories,
                    onToggle: () => setState(
                      () => _showAllCategories = !_showAllCategories,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _DashboardSection(uid: user.uid, data: data),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Top 4 values ────────────────────────────────────────────────────────────
class _AnalyticsValuesGrid extends StatelessWidget {
  const _AnalyticsValuesGrid({required this.data});
  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final curf = NumberFormat.currency(symbol: 'LE ', decimalDigits: 0);
    final projectedIncrease = data.projectedIncrease;

    final values = [
      (
        curf.format(data.totalRegisteredValue),
        l.analyticsValueOnRegistration,
        null,
        null,
      ),
      (
        curf.format(data.currentValue),
        data.totalRegisteredValue > 0
            ? '${(data.currentValue / data.totalRegisteredValue * 100).toStringAsFixed(1)}%'
            : '0%',
        data.currentValue >= data.totalRegisteredValue ? true : false,
        l.analyticsCurrentValue,
      ),
      (data.totalAssetsCount.toString(), 'Total Assets', null, null),
      (
        curf.format(projectedIncrease),
        l.analyticsProjectedIncrease,
        null,
        null,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6, // Aspect ratio for cards
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: values
              .map(
                (v) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          v.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (v.$3 != null) ...[
                            Icon(
                              v.$3 == true
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 14,
                              color: v.$3 == true
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              '${v.$2} ${v.$4 ?? ""}'.trim(),
                              style: TextStyle(
                                fontSize: 11,
                                color: v.$3 == true
                                    ? AppColors.success
                                    : (v.$3 == false
                                          ? AppColors.danger
                                          : AppColors.textSecondary),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── Multi-line chart ─────────────────────────────────────────────────────────
class _MultiLineChart extends StatelessWidget {
  const _MultiLineChart({required this.data});
  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: _LineChartPainter(data: data),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.sixMonthTrend.keys.map((m) {
                return Text(
                  m,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final AnalyticsData data;
  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final chartBottom = size.height - 22; // leave room for x-axis labels
    final chartHeight = chartBottom;
    final w = size.width;

    // Find max value across all trend series.
    double maxVal = 1.0;
    for (final values in data.sixMonthTrend.values) {
      for (final v in values) {
        if (v > maxVal) maxVal = v;
      }
    }

    final leftPad = 36.0;
    final cw = w - leftPad;

    // ── Y-axis labels + horizontal grid lines ─────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    const gridSteps = 4;
    for (var i = 0; i <= gridSteps; i++) {
      final fraction = i / gridSteps;
      final val = maxVal * (1 - fraction);
      final y = chartHeight * fraction;

      // Grid line
      canvas.drawLine(Offset(leftPad, y), Offset(w, y), gridPaint);

      // Y label
      textPainter.text = TextSpan(
        text: NumberFormat.compact().format(val),
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // ── Draw lines ────────────────────────────────────────────────────────
    void drawLine(List<double> ys, Color color) {
      if (ys.isEmpty) return;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      for (var i = 0; i < ys.length; i++) {
        final x = leftPad + (cw / (ys.length <= 1 ? 1 : ys.length - 1)) * i;
        final normalizedY = ys[i] / maxVal;
        final y =
            chartHeight -
            (normalizedY.isNaN || normalizedY.isInfinite ? 0 : normalizedY) *
                chartHeight;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    final regValues = <double>[];
    final curValues = <double>[];
    final projValues = <double>[];

    for (final values in data.sixMonthTrend.values) {
      regValues.add(values[0]);
      curValues.add(values[1]);
      projValues.add(values[2]);
    }

    // Green line (Current Value)
    drawLine(curValues, AppColors.success);
    // Blue line (Registered Value)
    drawLine(regValues, Colors.blue[800]!);
    // Yellow/gold line (Projected Increase)
    drawLine(projValues, const Color(0xFFFFC400));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Analysis Section ─────────────────────────────────────────────────────────
class _AnalysisSection extends StatelessWidget {
  const _AnalysisSection({
    required this.data,
    required this.showAll,
    required this.onToggle,
  });
  final AnalyticsData data;
  final bool showAll;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    // Find the max value across all categories for bar normalization
    double maxVal = 1.0;
    for (final values in data.analysisByCategory.values) {
      if (values[0] > maxVal) maxVal = values[0];
      if (values[1] > maxVal) maxVal = values[1];
      if (values[2] > maxVal) maxVal = values[2];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.analyticsAnalysis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          children: [
            Expanded(
              child: _LegendDot(
                color: Colors.blue[800]!,
                label: AppLocalizations.of(
                  context,
                )!.analyticsValueOnRegistration,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LegendDot(
                color: AppColors.success,
                label: AppLocalizations.of(context)!.analyticsCurrentValue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LegendDot(
                color: Colors.purple,
                label: AppLocalizations.of(context)!.analyticsProjectedIncrease,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (data.analysisByCategory.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No category data available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else ...[
          ...(showAll
                  ? data.analysisByCategory.entries
                  : data.analysisByCategory.entries.take(3))
              .map((entry) {
                final catName = entry.key;
                final vals = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          catName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Bar(
                              value: vals[0] / maxVal,
                              color: Colors.blue[800]!,
                            ),
                            const SizedBox(height: 3),
                            _Bar(
                              value: vals[1] / maxVal,
                              color: AppColors.success,
                            ),
                            const SizedBox(height: 3),
                            _Bar(value: vals[2] / maxVal, color: Colors.purple),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          if (data.analysisByCategory.length > 3)
            Center(
              child: TextButton(
                onPressed: onToggle,
                child: Text(showAll ? 'Show less' : 'Show more'),
              ),
            ),
        ],
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => Container(
        height: 5,
        width: c.maxWidth * value,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

// ── Dashboard Section ────────────────────────────────────────────────────────
class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.uid, required this.data});
  final String uid;
  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Prepare Category Donut Data
    final catEntries = data.analysisByCategory.entries.toList();
    final catColors = [
      Colors.teal,
      Colors.blue,
      const Color(0xFFE040FB),
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.lime,
      Colors.indigo,
    ];
    final catValues = <double>[];
    final catLabels = <String>[];
    double catTotal = 0;
    for (final e in catEntries) {
      catTotal += e.value[1]; // using currentValue
    }
    for (final e in catEntries) {
      catValues.add(catTotal == 0 ? 0 : e.value[1] / catTotal);
      catLabels.add(e.key);
    }

    // Prepare Status Donut Data
    final statEntries = data.analysisByStatus.entries.toList();
    final statColors = [
      Colors.teal,
      Colors.teal[200]!,
      Colors.orange,
      const Color(0xFFE040FB),
      Colors.blue,
      Colors.red,
    ];
    final statValues = <double>[];
    final statLabels = <String>[];
    double statTotal = 0;
    for (final e in statEntries) {
      statTotal += e.value;
    }
    for (final e in statEntries) {
      statValues.add(statTotal == 0 ? 0 : e.value / statTotal);
      statLabels.add(e.key);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.analyticsDashboard,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        // Asset Trends – interactive chart
        _AssetTrendsCard(data: data),

        const SizedBox(height: 16),

        // By Category & By Status
        Row(
          children: [
            Expanded(
              child: _DonutCard(
                title: 'By Category',
                colors: catColors,
                values: catValues.isEmpty ? [1.0] : catValues,
                labels: catLabels.isEmpty ? const ['All'] : catLabels,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DonutCard(
                title: 'By Status',
                colors: statColors,
                values: statValues.isEmpty ? [1.0] : statValues,
                labels: statLabels.isEmpty ? const ['All'] : statLabels,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Maintenance Costs
        StreamBuilder<MaintenanceData>(
          stream: context.read<AnalyticsService>().getMaintenanceDataStream(
            uid,
          ),
          builder: (context, snapshot) {
            final mData = snapshot.data ?? MaintenanceData.empty();
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maintenance Costs',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: CustomPaint(painter: _BarChartPainter(data: mData)),
                  ),
                  const SizedBox(height: 8),
                  // X labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: mData.costsByMonth.isEmpty
                        ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'].map((m) {
                            return Text(
                              m,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          }).toList()
                        : mData.costsByMonth.keys.map((m) {
                            return Text(
                              m,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('emergency', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 12),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.blue[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('scheduled', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Asset Trends interactive card ─────────────────────────────────────────────
class _AssetTrendsCard extends StatefulWidget {
  const _AssetTrendsCard({required this.data});
  final AnalyticsData data;

  @override
  State<_AssetTrendsCard> createState() => _AssetTrendsCardState();
}

class _AssetTrendsCardState extends State<_AssetTrendsCard> {
  // Index of the currently highlighted data point (-1 = none)
  int _hoveredIndex = -1;

  List<String> get _months => widget.data.sixMonthTrend.keys.toList();
  List<double> get _curValues {
    final vals = <double>[];
    for (final v in widget.data.sixMonthTrend.values) {
      vals.add(v[1]);
    }
    return vals;
  }

  void _updateHoverFromLocal(double localX, double chartWidth) {
    final months = _months;
    if (months.isEmpty) return;
    // Chart starts after a small left padding of 8px inside the card padding
    final n = months.length;
    if (n <= 1) return;
    final step = chartWidth / (n - 1);
    final idx = ((localX) / step).round().clamp(0, n - 1);
    if (idx != _hoveredIndex) {
      setState(() => _hoveredIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asset Trends',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '6 months overview',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      data.projectedIncrease > 0 && data.currentValue > 0
                          ? '+${(data.projectedIncrease / data.currentValue * 100).toStringAsFixed(1)}%'
                          : '0.0%',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Interactive chart area
          LayoutBuilder(
            builder: (context, constraints) {
              const chartHeight = 130.0;
              const xAxisHeight = 18.0;
              const totalHeight = chartHeight + xAxisHeight;
              final chartWidth = constraints.maxWidth;

              final months = _months;
              final curValues = _curValues;

              return GestureDetector(
                onTapDown: (d) =>
                    _updateHoverFromLocal(d.localPosition.dx, chartWidth),
                onHorizontalDragUpdate: (d) =>
                    _updateHoverFromLocal(d.localPosition.dx, chartWidth),
                onTapUp: (_) => setState(() => _hoveredIndex = -1),
                onHorizontalDragEnd: (_) => setState(() => _hoveredIndex = -1),
                child: SizedBox(
                  height: totalHeight,
                  width: chartWidth,
                  child: Stack(
                    children: [
                      // Main chart painter
                      Positioned.fill(
                        bottom: xAxisHeight,
                        child: CustomPaint(
                          painter: _TrendChartPainter(
                            data: data,
                            hoveredIndex: _hoveredIndex,
                          ),
                        ),
                      ),

                      // X-axis month labels
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: xAxisHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: months.map((m) {
                            return Text(
                              m,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Tooltip callout bubble
                      if (_hoveredIndex >= 0 &&
                          _hoveredIndex < months.length &&
                          months.isNotEmpty)
                        _buildTooltip(
                          chartWidth: chartWidth,
                          chartHeight: chartHeight,
                          months: months,
                          curValues: curValues,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip({
    required double chartWidth,
    required double chartHeight,
    required List<String> months,
    required List<double> curValues,
  }) {
    final n = months.length;
    if (n == 0 || _hoveredIndex < 0 || _hoveredIndex >= n) {
      return const SizedBox.shrink();
    }

    // Compute normalized Y
    double maxVal = 1.0;
    for (final v in curValues) {
      if (v > maxVal) maxVal = v;
    }
    final xStep = n <= 1 ? chartWidth : chartWidth / (n - 1);
    final xPos = _hoveredIndex * xStep;
    final yNorm = curValues.isNotEmpty
        ? (curValues[_hoveredIndex] / maxVal)
        : 0.0;
    final yPos = chartHeight - yNorm * chartHeight;

    const tooltipWidth = 100.0;
    const tooltipHeight = 40.0;
    const arrowH = 6.0;
    const bubbleRadius = 6.0;

    // Clamp tooltip so it stays within bounds
    double tipLeft = xPos - tooltipWidth / 2;
    final maxLeft = math.max(0.0, chartWidth - tooltipWidth);
    tipLeft = tipLeft.clamp(0.0, maxLeft);
    // Show tooltip above point, shifting up by bubble height+arrow
    double tipTop = yPos - tooltipHeight - arrowH - 6;
    if (tipTop < 0) tipTop = yPos + arrowH + 6;

    final monthLabel = months[_hoveredIndex];
    final valueLabel = NumberFormat.compact().format(
      curValues.isNotEmpty ? curValues[_hoveredIndex] : 0,
    );

    return Positioned(
      left: tipLeft,
      top: tipTop,
      child: Container(
        width: tooltipWidth,
        height: tooltipHeight,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(bubbleRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              monthLabel,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'assets $valueLabel',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trend chart painter ───────────────────────────────────────────────────────
class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({required this.data, this.hoveredIndex = -1});
  final AnalyticsData data;
  final int hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final curValues = <double>[];
    for (final values in data.sixMonthTrend.values) {
      curValues.add(values[1]); // Current value trend
    }

    // Normalize points
    double maxVal = 1.0;
    for (final v in curValues) {
      if (v > maxVal) maxVal = v;
    }

    final points = curValues.isEmpty ? [0.0] : curValues;
    final w = size.width;
    final h = size.height;
    final n = points.length;

    // ── Y-axis labels + horizontal grid lines ────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    const gridSteps = 4;
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (var i = 0; i <= gridSteps; i++) {
      final fraction = i / gridSteps;
      final val = maxVal * (1 - fraction);
      final y = h * fraction;

      // Dashed horizontal grid line
      _drawDashedLine(canvas, Offset(0, y), Offset(w, y), gridPaint);

      // Y label
      tp.text = TextSpan(
        text: NumberFormat.compact().format(val),
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      );
      tp.layout();
      tp.paint(canvas, Offset(2, y - 5));
    }

    // ── Area fill ────────────────────────────────────────────────────────
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.18),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final linePath = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = (w / (n <= 1 ? 1 : n - 1)) * i;
      final y = h - (points[i] / maxVal) * h;
      if (y.isNaN || y.isInfinite) continue;

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    if (points.isNotEmpty) {
      fillPath.lineTo(w, h);
      fillPath.lineTo(0, h);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(
        linePath,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // ── Hovered point crosshair + dot ────────────────────────────────────
    if (hoveredIndex >= 0 && hoveredIndex < points.length) {
      final x = (w / (n <= 1 ? 1 : n - 1)) * hoveredIndex;
      final y = h - (points[hoveredIndex] / maxVal) * h;

      // Vertical crosshair
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );

      // Outer ring
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      // Filled dot
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLen = 4.0;
    const gapLen = 3.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final nx = dx / len;
    final ny = dy / len;
    var pos = 0.0;
    while (pos < len) {
      final end = math.min(pos + dashLen, len);
      canvas.drawLine(
        Offset(from.dx + nx * pos, from.dy + ny * pos),
        Offset(from.dx + nx * end, from.dy + ny * end),
        paint,
      );
      pos += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.hoveredIndex != hoveredIndex || oldDelegate.data != data;
}

// ── Donut chart card ─────────────────────────────────────────────────────────
class _DonutCard extends StatelessWidget {
  const _DonutCard({
    required this.title,
    required this.colors,
    required this.values,
    required this.labels,
  });
  final String title;
  final List<Color> colors;
  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    // Build legend entries (up to first 4 slices to keep card compact)
    final legendCount = math.min(values.length, 4);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: CustomPaint(
              painter: _DonutPainter(colors: colors, values: values),
              size: const Size.square(90),
            ),
          ),
          const SizedBox(height: 10),
          // Colour legend
          if (labels.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(legendCount, (i) {
                final color = colors[i % colors.length];
                final pct = values.isNotEmpty
                    ? (values[i] * 100).toStringAsFixed(0)
                    : '0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          labels[i],
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.colors, required this.values});
  final List<Color> colors;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    var startAngle = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = 16
          ..style = PaintingStyle.stroke,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Bar chart painter ─────────────────────────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.data});
  final MaintenanceData data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.costsByMonth.isEmpty) return;

    final months = data.costsByMonth.values.toList();

    double maxVal = 1.0;
    for (final m in months) {
      if (m[0] > maxVal) maxVal = m[0];
      if (m[1] > maxVal) maxVal = m[1];
    }

    final barW = (size.width / months.length) * 0.35;
    const gap = 4.0;

    for (var i = 0; i < months.length; i++) {
      final x =
          (size.width / months.length) * i +
          (size.width / months.length - barW * 2 - gap) / 2;
      for (var j = 0; j < 2; j++) {
        final normalizedH = months[i][j] / maxVal;
        final bh =
            (normalizedH.isNaN || normalizedH.isInfinite ? 0.0 : normalizedH) *
            size.height;
        final bx = x + j * (barW + gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(bx, size.height - bh, barW, bh),
            const Radius.circular(3),
          ),
          Paint()..color = j == 0 ? Colors.red : Colors.blue[300]!,
        );
      }
    }

    // Y-axis labels
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    final steps = [maxVal, maxVal * 0.75, maxVal * 0.5, maxVal * 0.25, 0.0];
    for (var v in steps) {
      tp.text = TextSpan(
        text: v == 0 ? '0' : NumberFormat.compact().format(v),
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      );
      tp.layout();
      final y = size.height - (v / maxVal) * size.height;
      if (!y.isNaN && y >= 0 && y <= size.height) {
        tp.paint(canvas, Offset(0, y - 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
