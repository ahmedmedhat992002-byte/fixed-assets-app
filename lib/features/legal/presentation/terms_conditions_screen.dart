import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final sections = [
      l.legalTermsDefinitions,
      l.legalTermsAcceptance,
      l.legalTermsUserObligations,
      l.legalTermsAccountResp,
      l.legalTermsIP,
      l.legalTermsServiceMod,
      l.legalTermsLiability,
      l.legalTermsIndemnification,
      l.legalTermsTermination,
      l.legalTermsGovLaw,
      l.legalTermsDispute,
      l.legalTermsAmendments,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.complianceSettingsTermsConditions,
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
