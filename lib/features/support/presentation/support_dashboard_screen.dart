import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';

class SupportDashboardScreen extends StatefulWidget {
  const SupportDashboardScreen({super.key});

  @override
  State<SupportDashboardScreen> createState() => _SupportDashboardScreenState();
}

class _SupportDashboardScreenState extends State<SupportDashboardScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;

  int _openCount = 0;
  int _resolvedCount = 0;
  int _breachCount = 0; // Simulated

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final prefs = await SharedPreferences.getInstance();

    // Check Role
    _isAdmin =
        prefs.getBool('app_role_is_admin') ??
        true; // Defaulting to Admin for module demo

    // Parse Tickets
    final stored = prefs.getString('support_tickets_db');
    if (stored != null) {
      try {
        final List<dynamic> decoded = json.decode(stored);
        final tickets = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _openCount = tickets
            .where((t) => t['status'] != 'Resolved' && t['status'] != 'Closed')
            .length;
        _resolvedCount = tickets
            .where((t) => t['status'] == 'Resolved' || t['status'] == 'Closed')
            .length;
      } catch (_) {}
    } else {
      // Mock Data if fresh completely
      _openCount = 2;
      _resolvedCount = 14;
      _breachCount = 1;
    }

    setState(() => _isLoading = false);
  }

  Widget _buildKPICard(String title, int count, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isAdminLock = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: isAdminLock && !_isAdmin
            ? const Icon(Icons.lock_rounded, size: 18, color: AppColors.warning)
            : const Icon(Icons.chevron_right_rounded),
        onTap: isAdminLock && !_isAdmin ? null : onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.supportDashboardTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // KPI Row
          Row(
            children: [
              _buildKPICard(
                l.supportTicketsOpen,
                _openCount,
                AppColors.primary,
                Icons.support_agent_rounded,
              ),
              const SizedBox(width: 12),
              _buildKPICard(
                l.supportTicketsResolved,
                _resolvedCount,
                AppColors.success,
                Icons.task_alt_rounded,
              ),
              const SizedBox(width: 12),
              _buildKPICard(
                l.supportSLABreach,
                _breachCount,
                AppColors.danger,
                Icons.warning_rounded,
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            "Service Desk Operations",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          _buildMenuTile(
            l.supportCreateTicket,
            Icons.add_circle_outline_rounded,
            () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.createTicket).then((_) => _loadDashboard()),
          ),
          _buildMenuTile(
            l.supportTicketHistory,
            Icons.history_rounded,
            () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.ticketHistory).then((_) => _loadDashboard()),
          ),
          _buildMenuTile(
            l.supportKnowledgeBase,
            Icons.menu_book_rounded,
            () => Navigator.of(context).pushNamed(AppRoutes.knowledgeBase),
          ),

          const SizedBox(height: 32),
          Text(
            "Administrative Controls",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildMenuTile(
            l.supportSLAPolicy,
            Icons.policy_rounded,
            () => Navigator.of(context).pushNamed(AppRoutes.slaPolicy),
            isAdminLock: true,
          ),
        ],
      ),
    );
  }
}
