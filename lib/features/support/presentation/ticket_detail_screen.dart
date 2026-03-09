import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? ticketMap;

  const TicketDetailScreen({super.key, this.ticketMap});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late Map<String, dynamic> _ticket;
  bool _isAdmin = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticketMap ?? {};
    _verifyRole();
  }

  Future<void> _verifyRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdmin = prefs.getBool('app_role_is_admin') ?? true;
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('support_tickets_db');

    if (stored != null) {
      try {
        final List<dynamic> decoded = json.decode(stored);
        List<Map<String, dynamic>> tickets = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final idx = tickets.indexWhere((t) => t['id'] == _ticket['id']);
        if (idx != -1) {
          tickets[idx]['status'] = newStatus;
          tickets[idx]['lastUpdated'] = DateTime.now().toIso8601String();
          await prefs.setString('support_tickets_db', json.encode(tickets));

          setState(() {
            _ticket['status'] = newStatus;
            _ticket['lastUpdated'] = tickets[idx]['lastUpdated'];
          });
        }
      } catch (_) {}
    }

    setState(() => _isSaving = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status Updated successfully')),
    );
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_ticket.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No ticket data found')),
      );
    }

    final statuses = [
      'Open',
      'In Progress',
      'Awaiting User',
      'Resolved',
      'Closed',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _ticket['id'],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: SizedBox.shrink(),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _ticket['status'],
                        icon: const Icon(Icons.edit_note_rounded),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        items: statuses
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null && val != _ticket['status']) {
                            _updateStatus(val);
                          }
                        },
                      ),
                    ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    _ticket['status'],
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _ticket['status'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_ticket['status']),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.flag_rounded, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _ticket['priority'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _ticket['title'],
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${l.ticketCategory}: ${_ticket['category']}",
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const Divider(height: 32),

          Text(
            l.ticketDescription,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _ticket['description'] ?? 'No description provided.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),

          // Timeline Simulation
          const SizedBox(height: 32),
          Text(
            l.ticketConversation,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),

          _buildTimelineNode(
            context,
            title: "Ticket Submitted Systematically",
            subtitle: "User Account",
            time: _ticket['createdAt'],
            icon: Icons.person_rounded,
            color: cs.primary,
          ),
          _buildTimelineNode(
            context,
            title: "Status changed to ${_ticket['status']}",
            subtitle: "System Action",
            time: _ticket['lastUpdated'],
            icon: Icons.update_rounded,
            color: _getStatusColor(_ticket['status']),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(
    BuildContext ctx, {
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
    bool isLast = false,
  }) {
    final dtRaw = DateTime.parse(time);
    final formattedTime =
        "${dtRaw.day}/${dtRaw.month}/${dtRaw.year}  ${dtRaw.hour}:${dtRaw.minute.toString().padLeft(2, '0')}";
    final theme = Theme.of(ctx);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, size: 16, color: color),
            ),
            if (!isLast)
              Container(
                height: 48,
                width: 2,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
