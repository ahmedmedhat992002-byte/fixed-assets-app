import 'package:assets_management/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:assets_management/core/theme/app_colors.dart';
import 'package:assets_management/features/settings/data/notification_settings_controller.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final controller = context.watch<NotificationSettingsController>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                Text(
                  l.notifSettingsTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 32),
                _ToggleRow(
                  label: l.notifSettingsGeneral,
                  value: controller.general,
                  onChanged: (v) => controller.setGeneral(v),
                ),
                _ToggleRow(
                  label: l.notifSettingsSound,
                  value: controller.sound,
                  onChanged: (v) => controller.setSound(v),
                ),
                _ToggleRow(
                  label: l.notifSettingsVibrate,
                  value: controller.vibrate,
                  onChanged: (v) => controller.setVibrate(v),
                ),
                _ToggleRow(
                  label: l.notifSettingsSpecialOffers,
                  value: controller.specialOffers,
                  onChanged: (v) => controller.setSpecialOffers(v),
                ),
                _ToggleRow(
                  label: l.notifSettingsPromo,
                  value: controller.promoAndDiscount,
                  onChanged: (v) => controller.setPromo(v),
                ),
                _ToggleRow(
                  label: l.notifSettingsAppUpdates,
                  value: controller.appUpdates,
                  onChanged: (v) => controller.setAppUpdates(v),
                ),
                _ToggleRow(
                  label: l.notifSettingsNewService,
                  value: controller.newService,
                  onChanged: (v) => controller.setNewService(v),
                ),
                _ToggleRow(
                  label: l.notifSettingsNewTips,
                  value: controller.newTips,
                  onChanged: (v) => controller.setNewTips(v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await controller.saveSettings();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l.settingsUpdated)));
                    Navigator.of(context).pop();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l.settingsSave,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
