import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class AssetsSettingsScreen extends StatefulWidget {
  const AssetsSettingsScreen({super.key});

  @override
  State<AssetsSettingsScreen> createState() => _AssetsSettingsScreenState();
}

class _AssetsSettingsScreenState extends State<AssetsSettingsScreen> {
  bool _isLoading = true;

  // RBAC Mock Toggle
  bool _isAdmin = true;

  // Gen Config
  String _currency = 'USD';
  DateTime _fiscalYearStart = DateTime.now();

  // Dynamic Categories Schema
  // Structure: {name: String, type: String, depMethod: String, maintReq: bool, customFields: List<String>}
  List<Map<String, dynamic>> _categories = [];

  // Depreciation Engine
  String _depreciationMethod = 'Straight Line';
  int _usefulLife = 5;
  double _residualValue = 10.0;
  bool _autoCalculateDepreciation = true;

  // Fiscal & Financial
  double _taxRate = 15.0;
  double _capThreshold = 500.0;

  // Notification Policies
  int _maintReminderDays = 30;
  int _expiryReminderDays = 90;
  bool _depSummaryReport = true;
  int _contractRenewalDays = 60;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdmin = prefs.getBool('app_role_is_admin') ?? true;

      _currency = prefs.getString('assets_currency') ?? 'USD';
      final fyString = prefs.getString('assets_fiscal_year');
      if (fyString != null) {
        _fiscalYearStart = DateTime.tryParse(fyString) ?? DateTime.now();
      }

      final catsString = prefs.getString('assets_dynamic_categories');
      if (catsString != null) {
        try {
          final List decoded = json.decode(catsString);
          _categories = decoded
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } catch (_) {}
      } else {
        // Initial Mock Defaults
        _categories = [
          {
            'name': 'IT Hardware',
            'type': 'Physical',
            'depMethod': 'Straight Line',
            'maintReq': true,
            'customFields': ['Serial Number', 'MAC Address'],
          },
          {
            'name': 'Software Licenses',
            'type': 'Digital',
            'depMethod': 'Straight Line',
            'maintReq': false,
            'customFields': ['License Key', 'Seat Count'],
          },
        ];
      }

      _depreciationMethod =
          prefs.getString('assets_dep_method') ?? 'Straight Line';
      _usefulLife = prefs.getInt('assets_useful_life') ?? 5;
      _residualValue = prefs.getDouble('assets_residual_val') ?? 10.0;
      _autoCalculateDepreciation =
          prefs.getBool('assets_auto_calculate') ?? true;

      _taxRate = prefs.getDouble('assets_tax_rate') ?? 15.0;
      _capThreshold = prefs.getDouble('assets_cap_threshold') ?? 500.0;

      _maintReminderDays = prefs.getInt('assets_maint_rem') ?? 30;
      _expiryReminderDays = prefs.getInt('assets_exp_rem') ?? 90;
      _contractRenewalDays = prefs.getInt('assets_contr_rem') ?? 60;
      _depSummaryReport = prefs.getBool('assets_dep_sum') ?? true;

      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (!_isAdmin) {
      return; // RBAC Check
    }
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is DateTime) {
      await prefs.setString(key, value.toIso8601String());
    } else if (value is List) {
      await prefs.setString(key, json.encode(value));
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime current,
    Function(DateTime) onUpdate,
    String saveKey,
  ) async {
    if (!_isAdmin) {
      _showAccessDenied();
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != current) {
      setState(() => onUpdate(picked));
      _saveSetting(saveKey, picked);
    }
  }

  void _showAccessDenied() {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.assetsSettingsAccessDenied),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _showCategoryDialog({int? index}) {
    if (!_isAdmin) {
      _showAccessDenied();
      return;
    }

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEditing = index != null;

    final existing = isEditing
        ? _categories[index]
        : {
            'name': '',
            'type': 'Physical',
            'depMethod': 'Straight Line',
            'maintReq': false,
            'customFields': <String>[],
          };

    final nameCtrl = TextEditingController(text: existing['name']);
    String type = existing['type'];
    String depMethod = existing['depMethod'];
    bool maintReq = existing['maintReq'];
    List<String> currentFields = List<String>.from(existing['customFields']);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stCtx, stSetState) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              title: Text(
                isEditing
                    ? l.assetsSettingsEditCategory
                    : l.assetsSettingsAddCategory,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: l.assetsSettingsCategoryName,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: InputDecoration(
                        labelText: l.assetsSettingsAssetType,
                        border: const OutlineInputBorder(),
                      ),
                      items: ['Physical', 'Digital', 'Financial']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => stSetState(() => type = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: depMethod,
                      decoration: InputDecoration(
                        labelText: l.assetsSettingsDepreciationEngine,
                        border: const OutlineInputBorder(),
                      ),
                      items:
                          [
                                'Straight Line',
                                'Declining Balance',
                                'Units of Production',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) => stSetState(() => depMethod = v!),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.assetsSettingsMaintenanceRequired,
                        style: theme.textTheme.bodyMedium,
                      ),
                      value: maintReq,
                      onChanged: (v) => stSetState(() => maintReq = v),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.assetsSettingsCustomFields,
                          style: theme.textTheme.titleSmall,
                        ),
                        TextButton.icon(
                          onPressed: () {
                            stSetState(() {
                              currentFields.add(
                                'New Field ${currentFields.length + 1}',
                              );
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(l.assetsSettingsAddCustomField),
                        ),
                      ],
                    ),
                    ...currentFields.asMap().entries.map((fEntry) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(
                                  text: fEntry.value,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: l.assetsSettingsCustomFieldName,
                                ),
                                onChanged: (v) => currentFields[fEntry.key] = v,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.danger,
                              ),
                              onPressed: () => stSetState(
                                () => currentFields.removeAt(fEntry.key),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l.buttonCancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newObj = {
                      'name': nameCtrl.text.trim(),
                      'type': type,
                      'depMethod': depMethod,
                      'maintReq': maintReq,
                      'customFields': currentFields
                          .where((e) => e.isNotEmpty)
                          .toList(),
                    };
                    setState(() {
                      if (isEditing) {
                        _categories[index] = newObj;
                      } else {
                        _categories.add(newObj);
                      }
                    });
                    _saveSetting('assets_dynamic_categories', _categories);
                    Navigator.pop(ctx);
                  },
                  child: Text(l.buttonSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(int index) {
    if (!_isAdmin) {
      _showAccessDenied();
      return;
    }
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.assetsSettingsDeleteCategory),
        content: Text(l.assetsSettingsDeleteCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.buttonCancel),
          ),
          TextButton(
            onPressed: () {
              setState(() => _categories.removeAt(index));
              _saveSetting('assets_dynamic_categories', _categories);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l.buttonDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateGovernanceAction(String action) async {
    if (!_isAdmin) {
      _showAccessDenied();
      return;
    }
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SizedBox.shrink(),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.assetsSettingsArchiveSuccess),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _resetGovernance() async {
    if (!_isAdmin) {
      _showAccessDenied();
      return;
    }
    final l = AppLocalizations.of(context)!;
    final cnf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.assetsSettingsResetSettings),
        content: Text(l.assetsSettingsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.buttonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l.buttonConfirm),
          ),
        ],
      ),
    );

    if (cnf == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _loadSettings();
    }
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        enabled: _isAdmin,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l.settingsAssetsSettings,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        actions: [
          // Mock Role Toggle Tool for Demonstration/Testing
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  _isAdmin
                      ? l.assetsSettingsAdminMode
                      : l.assetsSettingsViewOnly,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isAdmin ? AppColors.success : AppColors.warning,
                  ),
                ),
                Switch(
                  value: _isAdmin,
                  onChanged: (v) async {
                    setState(() => _isAdmin = v);
                    final p = await SharedPreferences.getInstance();
                    p.setBool('app_role_is_admin', v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ExpansionTile(
            title: Text(
              l.assetsSettingsGeneralConfig,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: const Icon(
              Icons.settings_suggest_rounded,
              color: AppColors.primary,
            ),
            childrenPadding: const EdgeInsets.all(16),
            initiallyExpanded: true,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: InputDecoration(
                  labelText: l.assetsSettingsBaseCurrency,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['USD', 'EUR', 'GBP', 'SAR', 'AED']
                    .map(
                      (str) => DropdownMenuItem(value: str, child: Text(str)),
                    )
                    .toList(),
                onChanged: _isAdmin
                    ? (v) {
                        setState(() => _currency = v!);
                        _saveSetting('assets_currency', v);
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(
                  context,
                  _fiscalYearStart,
                  (d) => _fiscalYearStart = d,
                  'assets_fiscal_year',
                ),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.assetsSettingsFiscalYearStart,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_fiscalYearStart.day}/${_fiscalYearStart.month}/${_fiscalYearStart.year}",
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              l.assetsSettingsCategoriesMgmt,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: const Icon(
              Icons.category_rounded,
              color: AppColors.primary,
            ),
            childrenPadding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ..._categories.asMap().entries.map((entry) {
                final cat = entry.value;
                return ListTile(
                  title: Text(
                    cat['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${cat['type']} • ${cat['depMethod']} • ${cat['customFields'].length} Fields",
                  ),
                  trailing: _isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              onPressed: () =>
                                  _showCategoryDialog(index: entry.key),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: AppColors.danger,
                              ),
                              onPressed: () =>
                                  _confirmDeleteCategory(entry.key),
                            ),
                          ],
                        )
                      : null,
                );
              }),
              if (_isAdmin)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton.icon(
                    onPressed: () => _showCategoryDialog(),
                    icon: const Icon(Icons.add),
                    label: Text(l.assetsSettingsAddCategory),
                  ),
                ),
            ],
          ),
          ExpansionTile(
            title: Text(
              l.assetsSettingsDepreciationEngine,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: const Icon(
              Icons.trending_down_rounded,
              color: AppColors.primary,
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _depreciationMethod,
                decoration: InputDecoration(
                  labelText: l.assetsSettingsDefaultDepreciationMethod,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    [
                          'Straight Line',
                          'Declining Balance',
                          'Units of Production',
                        ]
                        .map(
                          (str) =>
                              DropdownMenuItem(value: str, child: Text(str)),
                        )
                        .toList(),
                onChanged: _isAdmin
                    ? (v) {
                        setState(() => _depreciationMethod = v!);
                        _saveSetting('assets_dep_method', v);
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                l.assetsSettingsUsefulLife,
                _usefulLife.toString(),
                (v) => _saveSetting('assets_useful_life', int.tryParse(v) ?? 5),
                isNumber: true,
              ),
              _buildTextField(
                l.assetsSettingsResidualValue,
                _residualValue.toString(),
                (v) => _saveSetting(
                  'assets_residual_val',
                  double.tryParse(v) ?? 10.0,
                ),
                isNumber: true,
              ),
              SwitchListTile(
                title: Text(l.assetsSettingsAutoCalculate),
                value: _autoCalculateDepreciation,
                onChanged: _isAdmin
                    ? (v) {
                        setState(() => _autoCalculateDepreciation = v);
                        _saveSetting('assets_auto_calculate', v);
                      }
                    : null,
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              l.assetsSettingsFiscalFinancial,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: const Icon(
              Icons.account_balance_rounded,
              color: AppColors.primary,
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              _buildTextField(
                l.assetsSettingsTaxRate,
                _taxRate.toString(),
                (v) =>
                    _saveSetting('assets_tax_rate', double.tryParse(v) ?? 15.0),
                isNumber: true,
              ),
              _buildTextField(
                l.assetsSettingsCapitalizationThreshold,
                _capThreshold.toString(),
                (v) => _saveSetting(
                  'assets_cap_threshold',
                  double.tryParse(v) ?? 500.0,
                ),
                isNumber: true,
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              l.assetsSettingsNotificationsAlerts,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              _buildTextField(
                l.assetsSettingsMaintenanceReminder,
                _maintReminderDays.toString(),
                (v) => _saveSetting('assets_maint_rem', int.tryParse(v) ?? 30),
                isNumber: true,
              ),
              _buildTextField(
                l.assetsSettingsExpiryReminder,
                _expiryReminderDays.toString(),
                (v) => _saveSetting('assets_exp_rem', int.tryParse(v) ?? 90),
                isNumber: true,
              ),
              _buildTextField(
                l.assetsSettingsContractRenewalReminder,
                _contractRenewalDays.toString(),
                (v) => _saveSetting('assets_contr_rem', int.tryParse(v) ?? 60),
                isNumber: true,
              ),
              SwitchListTile(
                title: Text(l.assetsSettingsDepreciationSummary),
                value: _depSummaryReport,
                onChanged: _isAdmin
                    ? (v) {
                        setState(() => _depSummaryReport = v);
                        _saveSetting('assets_dep_sum', v);
                      }
                    : null,
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              l.assetsSettingsDataGovernance,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primary,
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isAdmin
                      ? () => _simulateGovernanceAction('Export')
                      : null,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(l.assetsSettingsExportAssets),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isAdmin
                      ? () => _simulateGovernanceAction('Import')
                      : null,
                  icon: const Icon(Icons.upload_rounded),
                  label: Text(l.assetsSettingsImportAssets),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isAdmin
                      ? () => _simulateGovernanceAction('Archive')
                      : null,
                  icon: const Icon(Icons.archive_rounded),
                  label: Text(l.assetsSettingsArchiveOldAssets),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAdmin ? _resetGovernance : null,
                  icon: Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.onError),
                  label: Text(l.assetsSettingsResetSettings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
