import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:open_file/open_file.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/permissions/permission_service.dart';
import '../data/reports_service.dart';
import '../../../core/utils/report_export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    this.onOpenDrawer,
    this.isDrawerVisible = false,
    this.onReportTap,
  });

  final VoidCallback? onOpenDrawer;
  final bool isDrawerVisible;
  final VoidCallback? onReportTap;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();
  String _period = 'This Week';

  @override
  void initState() {
    super.initState();
    _recentReportsStream = _reportsService.getRecentReportsStream();
    _reportSummaryStream = _reportsService.getReportSummaryStream();
  }

  bool _isExporting = false;
  late Stream<List<GeneratedReport>> _recentReportsStream;
  late Stream<ReportSummary> _reportSummaryStream;

  static const _periods = ['Today', 'This Week', 'All'];

  Future<void> _handleExport(
    String format,
    ReportsData data,
    String reportType,
  ) async {
    if (_isExporting) return;

    // 1. Request Permission
    final hasPermission = await PermissionService.requestStoragePermission(
      context,
    );
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to export files.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Create Report Log
      final report = GeneratedReport(
        id: const Uuid().v4(),
        title: '$reportType (${format.toUpperCase()})',
        type: format.toUpperCase(),
        period: _period,
        generatedAt: DateTime.now(),
        subtitle: 'Exported exactly now',
        isGenerating: true,
      );

      // Save it as currently generating
      await _reportsService.saveReport(report);

      // Do the Export
      File? exportedFile;
      if (format == 'pdf') {
        exportedFile = await ReportExportService.exportToPdf(
          _period,
          data,
          reportType,
        );
      } else if (format == 'excel') {
        exportedFile = await ReportExportService.exportToExcel(
          _period,
          data,
          reportType,
        );
      } else if (format == 'csv') {
        exportedFile = await ReportExportService.exportToCsv(
          _period,
          data,
          reportType,
        );
      }

      // Update the log as finished
      await _reportsService.saveReport(
        GeneratedReport(
          id: report.id,
          title: report.title,
          type: report.type,
          period: report.period,
          generatedAt: report.generatedAt,
          subtitle: 'Generated successfully',
          isGenerating: false,
        ),
      );

      // Notify User
      if (exportedFile != null && await exportedFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved: ${exportedFile.path}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OPEN',
                textColor: Colors.white,
                onPressed: () {
                  OpenFile.open(exportedFile!.path);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export $format report: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () {},
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
      body: FutureBuilder<ReportsData>(
        future: _reportsService.fetchReportsData(_period),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading reports: ${snapshot.error}'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No data found.'));
          }

          final reportCards = [
            _ReportCardModel(
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFF3D5AF1),
              title: 'Assets Report',
              subtitle: 'Complete asset inventory and valuation',
              metricLabel: _period,
              metric: '${data.totalAssets}',
              badge:
                  '${data.assetGrowth >= 0 ? '+' : ''}${data.assetGrowth.toStringAsFixed(1)}%',
              badgePositive: data.assetGrowth >= 0,
              tags: [
                'Machinery: ${data.assetsByCategory['machinery']}',
                'Vehicles: ${data.assetsByCategory['vehicles']}',
                'Furniture: ${data.assetsByCategory['furniture']}',
                'New: ${data.newAssetsThisPeriod}',
                'Disposed: ${data.disposedAssets}',
              ],
            ),
            _ReportCardModel(
              icon: Icons.handyman_outlined,
              iconColor: const Color(0xFF3D5AF1),
              title: 'Maintenance Report',
              subtitle: 'Service history and schedules',
              metricLabel: _period,
              metric: '${data.totalMaintenance}',
              badge:
                  '${data.maintenanceGrowth >= 0 ? '+' : ''}${data.maintenanceGrowth.toStringAsFixed(1)}%',
              badgePositive: data.maintenanceGrowth >= 0,
              tags: [
                'Preventive: ${data.maintenanceByType['preventive']}',
                'Corrective: ${data.maintenanceByType['corrective']}',
                'Emergency: ${data.maintenanceByType['emergency']}',
                'In Maintenance: ${data.assetsInMaintenance}',
              ],
            ),
            _ReportCardModel(
              icon: Icons.attach_money_rounded,
              iconColor: const Color(0xFF3D5AF1),
              title: 'Financial Report',
              subtitle: 'Costs, depreciation, and ROI',
              metricLabel: _period,
              metric: '\$${data.totalPurchaseValue.toStringAsFixed(0)}',
              badge:
                  '', // ROI or generic financial growth can be placed here if calculated
              badgePositive: true,
              tags: [
                'Purchase: LE ${data.totalPurchaseValue.toStringAsFixed(0)}',
                'Maintenance: LE ${data.totalMaintenanceCost.toStringAsFixed(0)}',
                'Depreciation: LE ${data.totalDepreciation.toStringAsFixed(0)}',
                'NBV: LE ${(data.totalPurchaseValue - data.totalDepreciation).toStringAsFixed(0)}',
              ],
            ),
          ];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Title
              Text(
                'Reports',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),

              // Period filter tabs
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryLight, width: 2),
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

              const SizedBox(height: 20),

              if (_isExporting) const SizedBox(height: 4),
              const SizedBox(height: 10),

              // Report Cards
              ...reportCards.map(
                (card) => _ReportCardWidget(
                  card: card,
                  onPdfExport: () => _handleExport('pdf', data, card.title),
                  onExcelExport: () => _handleExport('excel', data, card.title),
                  onCsvExport: () => _handleExport('csv', data, card.title),
                ),
              ),

              const SizedBox(height: 8),

              // Recent Reports header
              Text(
                'Recent Reports',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              // Recent Reports list
              StreamBuilder<List<GeneratedReport>>(
                stream: _recentReportsStream,
                builder: (context, recentSnap) {
                  if (recentSnap.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  final reports = recentSnap.data ?? [];
                  if (reports.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No reports generated yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return Column(
                    children: reports
                        .map((r) => _RecentReportRow(report: r))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Report Summary Card
              StreamBuilder<ReportSummary>(
                stream: _reportSummaryStream,
                builder: (context, summarySnap) {
                  final summary = summarySnap.data;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FBFA),
                      border: Border.all(color: const Color(0xFFCCF0EB)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.pie_chart_outline_rounded,
                              color: Color(0xFF00B4D8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Report Summary',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _SummaryCell(
                              label: 'Total Reports',
                              value: '${summary?.totalReports ?? 0}',
                              valueColor: const Color(0xFF0284C7),
                            ),
                            _SummaryCell(
                              label: 'This Month',
                              value: '${summary?.thisMonthReports ?? 0}',
                              valueColor: AppColors.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _SummaryCell(
                              label: 'Scheduled',
                              value: '${summary?.scheduledReports ?? 0}',
                              valueColor: Colors.orange,
                            ),
                            _SummaryCell(
                              label: 'Automated',
                              value: '${summary?.automatedReports ?? 0}',
                              valueColor: Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary Cell ──────────────────────────────────────────────────────────────
class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Report Card Widget ────────────────────────────────────────────────────────
class _ReportCardWidget extends StatelessWidget {
  const _ReportCardWidget({
    required this.card,
    required this.onPdfExport,
    required this.onExcelExport,
    required this.onCsvExport,
  });

  final _ReportCardModel card;
  final VoidCallback onPdfExport;
  final VoidCallback onExcelExport;
  final VoidCallback onCsvExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: card.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.icon, color: card.iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      card.subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metric
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.metricLabel,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    card.metric,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (card.badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (card.badgePositive
                                ? AppColors.success
                                : AppColors.danger)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        card.badgePositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: card.badgePositive
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        card.badge,
                        style: TextStyle(
                          color: card.badgePositive
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: card.tags.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 12),
          // Export buttons
          Row(
            children: [
              _ExportButton(
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                color: Colors.red,
                onTap: onPdfExport,
              ),
              _ExportButton(
                icon: Icons.table_chart_outlined,
                label: 'Excel',
                color: AppColors.success,
                onTap: onExcelExport,
              ),
              _ExportButton(
                icon: Icons.description_outlined,
                label: 'CSV',
                color: AppColors.primary,
                onTap: onCsvExport,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent Report Row ─────────────────────────────────────────────────────────
class _RecentReportRow extends StatelessWidget {
  const _RecentReportRow({required this.report});
  final GeneratedReport report;

  Widget _buildActionButton(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData rIcon = Icons.document_scanner;
    Color rColor = AppColors.primary;

    if (report.type == 'PDF') {
      rIcon = Icons.picture_as_pdf;
      rColor = Colors.red;
    } else if (report.type == 'EXCEL') {
      rIcon = Icons.table_chart;
      rColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(rIcon, color: rColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  report.subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (report.isGenerating)
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: SizedBox.shrink(),
              ),
            )
          else ...[
            GestureDetector(
              onTap: () {},
              child: _buildActionButton(
                Icons.file_download_outlined,
                const Color(0xFFE0F2FE),
                const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {},
              child: _buildActionButton(
                Icons.share_outlined,
                Colors.grey.shade100,
                Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _ReportCardModel {
  const _ReportCardModel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.metricLabel,
    required this.metric,
    required this.badge,
    required this.badgePositive,
    required this.tags,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String metricLabel;
  final String metric;
  final String badge;
  final bool badgePositive;
  final List<String> tags;
}
