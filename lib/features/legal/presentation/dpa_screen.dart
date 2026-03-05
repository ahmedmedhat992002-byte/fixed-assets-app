import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';

class DpaScreen extends StatelessWidget {
  const DpaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final sections = [
      l.legalDPARoles,
      l.legalDPAPurpose,
      l.legalDPASubjects,
      l.legalDPADataCat,
      l.legalDPATechMeasures,
      l.legalDPASubProcessors,
      l.legalDPAIntTransfers,
      l.legalDPAAuditRights,
      l.legalDPABreach,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.complianceSettingsDPA,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ExpansionTile(
              title: Text(
                sections[index],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  l.legalTextPlaceholder,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
