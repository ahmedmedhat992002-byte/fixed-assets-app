import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('support_tickets_db');

    if (stored != null) {
      try {
        final List<dynamic> decoded = json.decode(stored);
        _tickets = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }

    if (_tickets.isEmpty) {
      // Mock Data
      _tickets = [
        {
          'id': 'TCK-2025-0002',
          'title': 'Server rack power supply failure',
          'category': 'Technical Issue',
          'priority': 'Critical',
          'status': 'Open',
          'createdAt': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'lastUpdated': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'description': 'Main datacenter sector 4 lost power redundency.',
        },
        {
          'id': 'TCK-2025-0001',
          'title': 'Error updating Asset depreciation method',
          'category': 'Asset Error',
          'priority': 'Medium',
          'status': 'Resolved',
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'lastUpdated': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'description':
              'System throws a 500 error when moving from straight line to declining balance.',
        },
      ];
    }

    setState(() => _isLoading = false);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.primary;
      case 'In Progress':
        return AppColors.warning;
      case 'Resolved':
        return AppColors.success;
      case 'Closed':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  Color _getPrioColor(String prio) {
    if (prio == 'Critical' || prio == 'High') return AppColors.danger;
    if (prio == 'Medium') return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.supportTicketHistory,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: _tickets.isEmpty
          ? Center(child: Text(l.kbNoResults))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: _tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final t = _tickets[idx];
                final dtRaw = DateTime.parse(t['createdAt']);
                final dateStr = "${dtRaw.day}/${dtRaw.month}/${dtRaw.year}";

                return InkWell(
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed(AppRoutes.ticketDetail, arguments: t)
                        .then((_) => _loadTickets());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t['id'],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  t['status'],
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t['status'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(t['status']),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  size: 16,
                                  color: _getPrioColor(t['priority']),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  t['priority'],
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Text(
                              dateStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
