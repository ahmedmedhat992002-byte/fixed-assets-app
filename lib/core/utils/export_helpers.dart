import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
// CSV package not used directly since we manual build csv
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/reports/data/reports_service.dart';

class ExportHelpers {
  static Future<void> exportReport({
    required String format, // 'pdf', 'excel', 'csv'
    required String period,
    required ReportsData data,
  }) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'Report_${period.replaceAll(' ', '_')}_$timestamp';
      File? file;

      if (format == 'pdf') {
        file = File('${tempDir.path}/$fileName.pdf');
        final pdf = _buildPdf(period, data);
        await file.writeAsBytes(await pdf.save());
      } else if (format == 'excel') {
        file = File('${tempDir.path}/$fileName.xlsx');
        final bytes = _buildExcel(period, data);
        await file.writeAsBytes(bytes);
      } else if (format == 'csv') {
        file = File('${tempDir.path}/$fileName.csv');
        final csvData = _buildCsv(period, data);
        await file.writeAsString(csvData);
      }

      if (file != null && await file.exists()) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Here is the generated $format report for $period.');
      }
    } catch (e) {
      debugPrint('Error exporting $format: $e');
      rethrow;
    }
  }

  static pw.Document _buildPdf(String period, ReportsData data) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Fixed Assets Report - $period',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'Assets Overview',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Total Assets: ${data.totalAssets} (${data.assetGrowth.toStringAsFixed(1)}% vs previous)',
              ),
              pw.Text(
                'Electronics: ${data.assetsByCategory['electronics']} | Furniture: ${data.assetsByCategory['furniture']} | Vehicles: ${data.assetsByCategory['vehicles']} | Equipment: ${data.assetsByCategory['equipment']}',
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'Maintenance Overview',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Total Maintenance: ${data.totalMaintenance} (${data.maintenanceGrowth.toStringAsFixed(1)}% vs previous)',
              ),
              pw.Text(
                'Preventive: ${data.maintenanceByType['preventive']} | Corrective: ${data.maintenanceByType['corrective']} | Emergency: ${data.maintenanceByType['emergency']} | Scheduled: ${data.maintenanceByType['scheduled']}',
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'Financial Overview',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Total Purchase Value: \$${data.totalPurchaseValue.toStringAsFixed(2)}',
              ),
              pw.Text(
                'Total Maintenance Cost: \$${data.totalMaintenanceCost.toStringAsFixed(2)}',
              ),
              pw.Text(
                'Total Depreciation: \$${data.totalDepreciation.toStringAsFixed(2)}',
              ),
              pw.Text(
                'Total Disposal Value: \$${data.totalDisposalValue.toStringAsFixed(2)}',
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'Generated on ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static List<int> _buildExcel(String period, ReportsData data) {
    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Report $period';

    sheet.getRangeByName('A1').setText('Category');
    sheet.getRangeByName('B1').setText('Value');

    sheet.getRangeByName('A2').setText('Total Assets');
    sheet.getRangeByName('B2').setNumber(data.totalAssets.toDouble());

    sheet.getRangeByName('A3').setText('Asset Growth (%)');
    sheet.getRangeByName('B3').setNumber(data.assetGrowth);

    sheet.getRangeByName('A4').setText('Total Maintenance');
    sheet.getRangeByName('B4').setNumber(data.totalMaintenance.toDouble());

    sheet.getRangeByName('A5').setText('Maintenance Growth (%)');
    sheet.getRangeByName('B5').setNumber(data.maintenanceGrowth);

    sheet.getRangeByName('A6').setText('Total Purchase Value');
    sheet.getRangeByName('B6').setNumber(data.totalPurchaseValue);

    sheet.getRangeByName('A7').setText('Total Maintenance Cost');
    sheet.getRangeByName('B7').setNumber(data.totalMaintenanceCost);

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  static String _buildCsv(String period, ReportsData data) {
    List<List<dynamic>> rows = [
      ['Category', 'Value'],
      ['Total Assets', data.totalAssets],
      ['Asset Growth (%)', data.assetGrowth.toStringAsFixed(2)],
      ['Total Maintenance', data.totalMaintenance],
      ['Maintenance Growth (%)', data.maintenanceGrowth.toStringAsFixed(2)],
      ['Total Purchase Value', data.totalPurchaseValue.toStringAsFixed(2)],
      ['Total Maintenance Cost', data.totalMaintenanceCost.toStringAsFixed(2)],
    ];
    return rows.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');
  }
}
