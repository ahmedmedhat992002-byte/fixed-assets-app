import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class SlaPolicyScreen extends StatefulWidget {
  const SlaPolicyScreen({super.key});

  @override
  State<SlaPolicyScreen> createState() => _SlaPolicyScreenState();
}

class _SlaPolicyScreenState extends State<SlaPolicyScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  double _lowHours = 72;
  double _medHours = 48;
  double _highHours = 24;
  double _critHours = 4;
  bool _autoEscalate = true;

  @override
  void initState() {
    super.initState();
    _loadSLA();
  }

  Future<void> _loadSLA() async {
    final prefs = await SharedPreferences.getInstance();

    // Simulate Admin Lockout visually (if a user somehow routes here directly)
    final isAdmin = prefs.getBool('app_role_is_admin') ?? true;
    if (!isAdmin) {
      if (mounted) Navigator.pop(context); // Eject standard users instantly
      return;
    }

    setState(() {
      _lowHours = prefs.getDouble('sla_low') ?? 72;
      _medHours = prefs.getDouble('sla_medium') ?? 48;
      _highHours = prefs.getDouble('sla_high') ?? 24;
      _critHours = prefs.getDouble('sla_critical') ?? 4;
      _autoEscalate = prefs.getBool('sla_escalate') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSLA() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('sla_low', _lowHours);
    await prefs.setDouble('sla_medium', _medHours);
    await prefs.setDouble('sla_high', _highHours);
    await prefs.setDouble('sla_critical', _critHours);
    await prefs.setBool('sla_escalate', _autoEscalate);

    await Future.delayed(
      const Duration(milliseconds: 600),
    ); // Simulate networking

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SLA Configuration Updated'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildSlider(
    String label,
    double val,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              "${val.toInt()}h",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: val,
          min: 1,
          max: max,
          divisions: max.toInt(),
          label: "${val.toInt()} hours",
          onChanged: onChanged,
        ),
      ],
    );
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
          l.slaPolicyTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text(
                      "Response Thresholds",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSlider(
                  l.slaLowThreshold,
                  _lowHours,
                  168,
                  (v) => setState(() => _lowHours = v),
                ),
                const Divider(height: 24),
                _buildSlider(
                  l.slaMediumThreshold,
                  _medHours,
                  72,
                  (v) => setState(() => _medHours = v),
                ),
                const Divider(height: 24),
                _buildSlider(
                  l.slaHighThreshold,
                  _highHours,
                  48,
                  (v) => setState(() => _highHours = v),
                ),
                const Divider(height: 24),
                _buildSlider(
                  l.slaCriticalThreshold,
                  _critHours,
                  24,
                  (v) => setState(() => _critHours = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: SwitchListTile(
              title: Text(
                l.slaAutoEscalate,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Automatically elevate priority if response threshold is breached.",
              ),
              value: _autoEscalate,
              onChanged: (v) => setState(() => _autoEscalate = v),
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 48),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSLA,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: const SizedBox.shrink(),
                    )
                  : const Text(
                      "Save SLA Configuration",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
