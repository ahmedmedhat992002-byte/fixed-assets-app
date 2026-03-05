import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';

class ComplianceSettingsScreen extends StatefulWidget {
  const ComplianceSettingsScreen({super.key});

  @override
  State<ComplianceSettingsScreen> createState() =>
      _ComplianceSettingsScreenState();
}

class _ComplianceSettingsScreenState extends State<ComplianceSettingsScreen> {
  bool _isLoading = true;

  // Consent toggles
  bool _consentPrivacy = false;
  bool _consentTerms = false;
  bool _consentNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _consentPrivacy = prefs.getBool('consent_privacy') ?? false;
      _consentTerms = prefs.getBool('consent_terms') ?? false;
      _consentNotifications = prefs.getBool('consent_notifications') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _updateConsent(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    // Simulate logging the timestamp locally
    await prefs.setString('${key}_timestamp', DateTime.now().toIso8601String());

    if (mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? l.complianceSettingsConsentGranted
                : l.complianceSettingsConsentWithdrawn,
          ),
          backgroundColor: value ? AppColors.success : AppColors.warning,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _simulateDataRequest(String type) async {
    final l = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SizedBox.shrink(),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.pop(context);

    final msg = type == 'export'
        ? l.complianceSettingsExportSimulate
        : l.complianceSettingsDeletionSimulate;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: type == 'export'
            ? AppColors.primary
            : AppColors.danger,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.complianceSettingsTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _buildSectionHeader(l.complianceSettingsLegalDocs),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: Text(l.complianceSettingsPrivacyPolicy),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(l.complianceSettingsTermsConditions),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.termsConditions),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(l.complianceSettingsDPA),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.dpa),
                ),
              ],
            ),
          ),

          _buildSectionHeader(l.complianceSettingsConsentMgmt),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l.complianceSettingsConsentPrivacy),
                  value: _consentPrivacy,
                  onChanged: (val) {
                    setState(() => _consentPrivacy = val);
                    _updateConsent('consent_privacy', val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(l.complianceSettingsConsentTerms),
                  value: _consentTerms,
                  onChanged: (val) {
                    setState(() => _consentTerms = val);
                    _updateConsent('consent_terms', val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(l.complianceSettingsConsentNotifications),
                  value: _consentNotifications,
                  onChanged: (val) {
                    setState(() => _consentNotifications = val);
                    _updateConsent('consent_notifications', val);
                  },
                ),
              ],
            ),
          ),

          _buildSectionHeader('Governance'),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(l.complianceSettingsAuditLogs),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.auditLogs),
                ),
              ],
            ),
          ),

          _buildSectionHeader(l.complianceSettingsDataSubjectRights),
          OutlinedButton.icon(
            onPressed: () => _simulateDataRequest('export'),
            icon: const Icon(Icons.download_rounded),
            label: Text(l.complianceSettingsRequestDataExport),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _simulateDataRequest('delete'),
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(l.complianceSettingsRequestAccountDeletion),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
