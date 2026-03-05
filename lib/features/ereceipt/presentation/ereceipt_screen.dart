import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/receipt_data.dart';

class EReceiptScreen extends StatelessWidget {
  const EReceiptScreen({super.key, required this.data});

  final ReceiptData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.primary, height: 1.2),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'E-Receipt',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onSelected: (v) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$v – coming soon')),
                          );
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'Share PDF',
                            child: Row(
                              children: const [
                                Icon(Icons.send_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('Share PDF'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'Download PDF',
                            child: Row(
                              children: const [
                                Icon(Icons.download_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('Download PDF'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'Print',
                            child: Row(
                              children: const [
                                Icon(Icons.print_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('Print'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Barcode card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DDFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          width: double.infinity,
                          child: CustomPaint(painter: _BarcodePainter()),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data.barcodeValue,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF1A3B1A),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  Text(
                    'Details E-Receipt',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sender
                  _DetailRow(label: 'Sender Name', value: data.senderName),
                  _DetailRow(label: 'Phone Number', value: data.senderPhone),
                  _DetailRow(label: 'Email address', value: data.senderEmail),
                  _DetailRow(label: 'Address', value: data.senderAddress),
                  const Divider(height: 28),

                  // Receiver
                  _DetailRow(label: 'Receiver Name', value: data.receiverName),
                  _DetailRow(label: 'Phone Number', value: data.receiverPhone),
                  _DetailRow(label: 'Email address', value: data.receiverEmail),
                  _DetailRow(label: 'Address', value: data.receiverAddress),
                  const Divider(height: 28),

                  // Payment info
                  _DetailRow(
                    label: 'Total',
                    value: '${data.currency}${data.total.toStringAsFixed(2)}',
                  ),
                  _DetailRow(
                    label: 'Payment Method',
                    value: data.paymentMethod,
                  ),
                  _TrackRow(trackId: data.transactionId),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.secondary),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data.status,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.files, (r) => false),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Next to home page',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barcode painter ───────────────────────────────────────────────────────────
class _BarcodePainter extends CustomPainter {
  static const _seed = [
    3,
    1,
    2,
    4,
    1,
    3,
    2,
    1,
    4,
    2,
    1,
    3,
    2,
    4,
    1,
    2,
    3,
    1,
    4,
    2,
    1,
    2,
    3,
    1,
    2,
    4,
    3,
    1,
    2,
    1,
    4,
    3,
    2,
    1,
    3,
    4,
    2,
    1,
    3,
    2,
    4,
    1,
    3,
    2,
    1,
    4,
    2,
    3,
    1,
    2,
    4,
    3,
    1,
    2,
    4,
    1,
    3,
    2,
    1,
    4,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = const Color(0xFF1A3B1A);
    final unit = size.width / _seed.fold<int>(0, (s, e) => s + e);
    double x = 0;
    bool dark = true;
    for (final w in _seed) {
      final barW = unit * w;
      if (dark) {
        canvas.drawRect(Rect.fromLTWH(x, 0, barW, size.height), darkPaint);
      }
      x += barW;
      dark = !dark;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Detail row ────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Track ID row with copy ────────────────────────────────────────────────────
class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.trackId});
  final String trackId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Transaction & Track ID',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            children: [
              Text(
                trackId,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: trackId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Track ID copied')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
