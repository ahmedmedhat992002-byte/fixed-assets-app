import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../features/reports/data/reports_service.dart';

class ReportExportService {
  static Future<File?> exportToPdf(
    String period,
    ReportsData data,
    String reportType,
  ) async {
    return await _exportReport(
      format: 'pdf',
      period: period,
      data: data,
      reportType: reportType,
    );
  }

  static Future<File?> exportToExcel(
    String period,
    ReportsData data,
    String reportType,
  ) async {
    return await _exportReport(
      format: 'excel',
      period: period,
      data: data,
      reportType: reportType,
    );
  }

  static Future<File?> exportToCsv(
    String period,
    ReportsData data,
    String reportType,
  ) async {
    return await _exportReport(
      format: 'csv',
      period: period,
      data: data,
      reportType: reportType,
    );
  }

  static Future<File?> _exportReport({
    required String format, // 'pdf', 'excel', 'csv'
    required String period,
    required ReportsData data,
    required String reportType, // 'Assets', 'Maintenance', 'Financial'
  }) async {
    try {
      // 1. Determine Save Directory
      Directory? saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          saveDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        saveDir = await getApplicationDocumentsDirectory();
      } else {
        saveDir = await getTemporaryDirectory();
      }

      if (saveDir == null) {
        throw Exception('Could not determine save directory.');
      }

      String timestamp = DateTime.now().toIso8601String().split('T').first;
      String safePeriod = period.replaceAll(' ', '_').toLowerCase();
      String safeType = reportType.replaceAll(' ', '_').toLowerCase();
      String fileName = '${safeType}_report_${safePeriod}_$timestamp';
      File? file;

      // 2. Generate File Content
      if (format == 'pdf') {
        file = File('${saveDir.path}/$fileName.pdf');
        final pdf = _buildPdf(period, data, reportType);
        await file.writeAsBytes(await pdf.save());
      } else if (format == 'excel') {
        file = File('${saveDir.path}/$fileName.xlsx');
        final bytes = _buildExcel(period, data, reportType);
        await file.writeAsBytes(bytes);
      } else if (format == 'csv') {
        file = File('${saveDir.path}/$fileName.csv');
        final csvData = _buildCsv(period, data, reportType);
        await file.writeAsString(csvData);
      }

      return file;
    } catch (e) {
      throw Exception('Failed to save $format report: $e');
    }
  }

  // --- File Builders ---

  static pw.Document _buildPdf(
    String period,
    ReportsData data,
    String reportType,
  ) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  '$reportType Summary Report - $period',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),

              if (reportType == 'Assets Report') ...[
                _pdfSectionTitle('Key Performance Indicators'),
                _pdfMetricRow(
                  'Total Assets',
                  '${data.totalAssets}',
                  'Growth: ${data.assetGrowth.toStringAsFixed(1)}%',
                ),
                _pdfMetricRow(
                  'New Assets',
                  '${data.newAssetsThisPeriod}',
                  'Disposed: ${data.disposedAssets}',
                ),
                _pdfSectionTitle('Asset Distribution'),
                pw.Text(
                  'Machinery: ${data.assetsByCategory['machinery'] ?? 0} | '
                  'Vehicles: ${data.assetsByCategory['vehicles'] ?? 0} | '
                  'Furniture: ${data.assetsByCategory['furniture'] ?? 0} | '
                  'IT: ${(data.assetsByCategory['computer hardware'] ?? 0) + (data.assetsByCategory['computer software'] ?? 0)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],

              if (reportType == 'Maintenance Report') ...[
                _pdfSectionTitle('Maintenance Overview'),
                _pdfMetricRow(
                  'Total Tasks',
                  '${data.totalMaintenance}',
                  'Growth: ${data.maintenanceGrowth.toStringAsFixed(1)}%',
                ),
                _pdfMetricRow(
                  'Assets in Maintenance',
                  '${data.assetsInMaintenance}',
                  '',
                ),
                _pdfMetricRow(
                  'Total Maintenance Cost',
                  'LE ${data.totalMaintenanceCost.toStringAsFixed(0)}',
                  '',
                ),
                _pdfSectionTitle('Distribution by Type'),
                pw.Text(
                  'Preventive: ${data.maintenanceByType['preventive'] ?? 0} | '
                  'Corrective: ${data.maintenanceByType['corrective'] ?? 0} | '
                  'Emergency: ${data.maintenanceByType['emergency'] ?? 0}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],

              if (reportType == 'Financial Report') ...[
                _pdfSectionTitle('Financial Overview'),
                _pdfMetricRow(
                  'Total Purchase Cost',
                  'LE ${data.totalPurchaseValue.toStringAsFixed(0)}',
                  '',
                ),
                _pdfMetricRow(
                  'Accumulated Depreciation',
                  'LE ${data.totalDepreciation.toStringAsFixed(0)}',
                  '',
                ),
                _pdfMetricRow(
                  'Net Book Value',
                  'LE ${(data.totalPurchaseValue - data.totalDepreciation).toStringAsFixed(0)}',
                  '',
                ),
                _pdfMetricRow(
                  'Total Maintenance Cost',
                  'LE ${data.totalMaintenanceCost.toStringAsFixed(0)}',
                  '',
                ),
              ],

              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on ${DateTime.now().toLocal().toString().split('.')[0]}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'Page 1/1',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _pdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.blue100),
        ],
      ),
    );
  }

  static pw.Widget _pdfMetricRow(String label, String value, String subValue) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Row(
            children: [
              if (subValue.isNotEmpty)
                pw.Text(
                  subValue,
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              pw.SizedBox(width: 10),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<int> _buildExcel(
    String period,
    ReportsData data,
    String reportType,
  ) {
    final xlsio.Workbook workbook = xlsio.Workbook();

    if (reportType == 'Assets Report' || reportType == 'Financial Report') {
      // ── Sheet: Dashboard KPI (Included in Assets and Financial) ──────────
      final xlsio.Worksheet dashSheet = workbook.worksheets[0];
      dashSheet.name = 'Dashboard';

      dashSheet.getRangeByName('A1:B1').merge();
      dashSheet.getRangeByName('A1').setText('$reportType Summary - $period');
      dashSheet.getRangeByName('A1').cellStyle.fontSize = 14;

      final kpis = reportType == 'Assets Report'
          ? [
              ['Total Assets', data.totalAssets],
              ['Asset Growth (%)', data.assetGrowth],
              ['New Assets (This Period)', data.newAssetsThisPeriod],
              ['Disposed Assets', data.disposedAssets],
            ]
          : [
              ['Total Purchase Value', data.totalPurchaseValue],
              ['Total Depreciation', data.totalDepreciation],
              [
                'Net Book Value',
                data.totalPurchaseValue - data.totalDepreciation,
              ],
              ['Total Maintenance Cost', data.totalMaintenanceCost],
            ];

      for (int i = 0; i < kpis.length; i++) {
        dashSheet.getRangeByIndex(i + 3, 1).setText(kpis[i][0].toString());
        dashSheet.getRangeByIndex(i + 3, 2).setValue(kpis[i][1]);
      }

      // ── Sheet: Asset Register (Always included for Assets/Financial) ─────
      final xlsio.Worksheet assetSheet = workbook.worksheets.addWithName(
        'Asset Register',
      );
      final assetHeaders = [
        'Asset ID',
        'Asset Name',
        'Category',
        'Purchase Date',
        'Purchase Cost',
        'Location',
        'Department',
        'Status',
        'Useful Life',
        'Depreciation Method',
        'Acc. Depreciation',
        'Net Book Value',
        'Vendor',
      ];

      for (int i = 0; i < assetHeaders.length; i++) {
        assetSheet.getRangeByIndex(1, i + 1).setText(assetHeaders[i]);
        assetSheet.getRangeByIndex(1, i + 1).cellStyle.backColor = '#D3D3D3';
      }

      for (int i = 0; i < data.allAssets.length; i++) {
        final a = data.allAssets[i];
        final accDep = a.purchasePrice - a.currentValue;
        final nbv = a.currentValue;

        final row = [
          a.id,
          a.name,
          a.category,
          a.purchaseDateMs != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  a.purchaseDateMs!,
                ).toString().split(' ')[0]
              : 'N/A',
          a.purchasePrice,
          a.location ?? '',
          a.department ?? '',
          a.status,
          a.usefulLife ?? 0,
          a.depreciationMethod,
          accDep,
          nbv,
          a.vendor ?? '',
        ];

        for (int j = 0; j < row.length; j++) {
          final val = row[j];
          final range = assetSheet.getRangeByIndex(i + 2, j + 1);
          if (val is num) {
            range.setNumber(val.toDouble());
          } else {
            range.setText(val.toString());
          }
        }
      }
    }

    if (reportType == 'Maintenance Report') {
      // ── Sheet: Maintenance ───────────────────────────────────────────────
      final xlsio.Worksheet maintSheet = workbook.worksheets[0];
      maintSheet.name = 'Maintenance History';

      final maintHeaders = [
        'Asset ID',
        'Asset Name',
        'Date',
        'Type',
        'Cost',
        'Technician/Vendor',
        'Notes',
      ];

      for (int i = 0; i < maintHeaders.length; i++) {
        maintSheet.getRangeByIndex(1, i + 1).setText(maintHeaders[i]);
        maintSheet.getRangeByIndex(1, i + 1).cellStyle.backColor = '#FFE4B5';
      }

      for (int i = 0; i < data.allMaintenance.length; i++) {
        final m = data.allMaintenance[i];
        final row = [
          m.assetId,
          m.assetName,
          DateTime.fromMillisecondsSinceEpoch(
            m.dateMs,
          ).toString().split(' ')[0],
          m.type,
          m.cost,
          m.technician ?? m.vendor ?? 'N/A',
          m.notes ?? '',
        ];

        for (int j = 0; j < row.length; j++) {
          final val = row[j];
          final range = maintSheet.getRangeByIndex(i + 2, j + 1);
          if (val is num) {
            range.setNumber(val.toDouble());
          } else {
            range.setText(val.toString());
          }
        }
      }
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  static String _buildCsv(String period, ReportsData data, String reportType) {
    if (reportType == 'Maintenance Report') {
      List<List<dynamic>> rows = [
        ['MAINTENANCE HISTORY - $period'],
        ['Asset ID', 'Asset Name', 'Date', 'Type', 'Cost', 'Technician/Vendor'],
      ];
      for (var m in data.allMaintenance) {
        rows.add([
          m.assetId.substring(0, 8),
          m.assetName,
          DateTime.fromMillisecondsSinceEpoch(
            m.dateMs,
          ).toString().split(' ')[0],
          m.type,
          m.cost,
          m.technician ?? m.vendor ?? 'N/A',
        ]);
      }
      return rows
          .map((row) => row.map((cell) => '"$cell"').join(','))
          .join('\n');
    }

    // Default to Asset Register for Assets/Financial in CSV
    List<List<dynamic>> rows = [
      ['$reportType REGISTER - $period'],
      ['Asset ID', 'Name', 'Category', 'Cost', 'Location', 'Status', 'NBV'],
    ];

    for (var a in data.allAssets) {
      rows.add([
        a.id.substring(0, 8),
        a.name,
        a.category,
        a.purchasePrice,
        a.location ?? '',
        a.status,
        a.currentValue,
      ]);
    }

    return rows.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');
  }
}
