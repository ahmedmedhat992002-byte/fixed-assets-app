import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Simulate a hardcoded list of audit events
    final mockEvents = [
      {
        'action': l.auditLogConfigAction,
        'timestamp': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
        'userRole': 'Admin',
        'entity': 'Assets Settings - Depreciation Engine',
        'icon': Icons.settings_suggest_rounded,
        'color': AppColors.primary,
      },
      {
        'action': l.auditLogLoginAction,
        'timestamp': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'userRole': 'User',
        'entity': 'Auth Service',
        'icon': Icons.login_rounded,
        'color': AppColors.success,
      },
      {
        'action': l.auditLogAssetDeletion,
        'timestamp': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'userRole': 'Admin',
        'entity': 'Asset ID: #MAC-298',
        'icon': Icons.delete_forever_rounded,
        'color': AppColors.danger,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.complianceSettingsAuditLogs,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemCount: mockEvents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final event = mockEvents[index];
          final timestampRaw = DateTime.parse(event['timestamp'] as String);
          final formattedTime =
              "${timestampRaw.day}/${timestampRaw.month}/${timestampRaw.year}  ${timestampRaw.hour}:${timestampRaw.minute.toString().padLeft(2, '0')}";

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: (event['color'] as Color).withValues(
                    alpha: 0.2,
                  ),
                  foregroundColor: event['color'] as Color,
                  child: Icon(event['icon'] as IconData),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['action'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("${l.auditLogEntity}: ${event['entity']}"),
                      Text("${l.auditLogUserRole}: ${event['userRole']}"),
                    ],
                  ),
                ),
                Flexible(
                  child: Text(
                    formattedTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
