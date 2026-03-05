import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/sync/models/asset_local.dart';
import 'package:assets_management/shared/widgets/app_bottom_nav.dart';

class DepreciationScheduleScreen extends StatelessWidget {
  const DepreciationScheduleScreen({super.key, required this.asset});

  final AssetLocal asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color.fromARGB(255, 226, 228, 231),
              child: const Icon(
                Icons.person,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.primary, height: 1.2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              asset.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            Text(
              'Depreciation Schedule',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _TableHeader(),
                  ..._buildScheduleRows(),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'This schedule is calculated using the ${asset.depreciationMethod.replaceAll('_', ' ')} Method',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ExportButton(
                  label: 'Export to Excel',
                  fileType: 'XLSX',
                  color: Colors.green,
                ),
                _ExportButton(
                  label: 'Export to PDF',
                  fileType: 'PDF',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  List<Widget> _buildScheduleRows() {
    final currencyFormat = NumberFormat.compact(locale: 'en_US');
    final purchasePrice = asset.purchasePrice;
    final salvageValue = asset.salvageValue ?? 0.0;
    final usefulLife = asset.usefulLife ?? 5;
    final annualDepreciation = (purchasePrice - salvageValue) / usefulLife;

    final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
      asset.purchaseDateMs ?? DateTime.now().millisecondsSinceEpoch,
    );
    final startYear = purchaseDate.year;

    return List.generate(usefulLife, (index) {
      final year = startYear + index;
      final openingValue = purchasePrice - (annualDepreciation * index);
      final closingValue = openingValue - annualDepreciation;
      final accumulated = annualDepreciation * (index + 1);

      return _TableRow(
        year: year.toString(),
        expense: currencyFormat.format(annualDepreciation),
        accumulated: currencyFormat.format(accumulated),
        bookValue: currencyFormat.format(
          closingValue.clamp(salvageValue, purchasePrice),
        ),
      );
    });
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 1,
            child: Text(
              'Year',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Depreciation\nExpense',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Accumulated\nDepreciation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Book\nValue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String year;
  final String expense;
  final String accumulated;
  final String bookValue;

  const _TableRow({
    required this.year,
    required this.expense,
    required this.accumulated,
    required this.bookValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(year, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(expense, textAlign: TextAlign.center)),
          Expanded(
            flex: 2,
            child: Text(accumulated, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 1,
            child: Text(bookValue, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final String fileType;
  final Color color;

  const _ExportButton({
    required this.label,
    required this.fileType,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Text(
            fileType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
