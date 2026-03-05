import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.complianceSettingsPrivacyPolicy)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          l.legalTextPlaceholder,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ),
    );
  }
}
