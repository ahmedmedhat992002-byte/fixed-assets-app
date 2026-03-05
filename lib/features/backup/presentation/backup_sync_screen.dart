import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/backup/backup_service.dart';
import '../../../core/theme/app_colors.dart';

class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  bool _isLoading = true;
  bool _isBackingUp = false;

  // Sync Overview State
  String _lastSync = 'Never';
  String _syncStatus = 'Offline';
  int _pendingChanges = 0;
  int _recordsCount = 0;

  // Registered email from Firebase Auth
  String _userEmail = '';

  // Auto Settings
  bool _autoSync = false;
  bool _wifiOnly = true;
  bool _launchSync = false;
  bool _backgroundSync = true;

  // Policy Tracking
  String _frequency = 'Daily';
  String _conflictStrategy = 'Keep Server Version';

  // Data Scopes
  final Map<String, bool> _scopes = {
    'Assets': true,
    'Contracts': true,
    'Tickets': false,
    'Settings': true,
    'Audit Logs': false,
  };

  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    // Read registered email from Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final email = firebaseUser?.email ?? '';

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = email;

      _lastSync = prefs.getString('backup_last_sync') ?? 'Never';
      _syncStatus = prefs.getString('backup_status') ?? 'Offline';
      _recordsCount = prefs.getInt('backup_records_count') ?? 0;

      _autoSync = prefs.getBool('backup_auto') ?? false;
      _wifiOnly = prefs.getBool('backup_wifi') ?? true;
      _launchSync = prefs.getBool('backup_launch') ?? false;
      _backgroundSync = prefs.getBool('backup_bg') ?? true;

      _frequency = prefs.getString('backup_frequency') ?? 'Daily';
      _conflictStrategy =
          prefs.getString('backup_conflict') ?? 'Keep Server Version';

      final rawScopes = prefs.getString('backup_scopes');
      if (rawScopes != null) {
        try {
          final decoded = json.decode(rawScopes) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            if (_scopes.containsKey(key)) {
              _scopes[key] = value as bool;
            }
          });
        } catch (_) {}
      }

      _isLoading = false;
    });
  }

  Future<void> _saveToggle(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _saveString(String key, String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, val);
  }

  Future<void> _saveScopes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_scopes', json.encode(_scopes));
  }

  // ── Real Backup ────────────────────────────────────────────────────────────

  Future<void> _triggerBackup() async {
    if (_isBackingUp) return;

    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;

    setState(() => _isBackingUp = true);

    try {
      final result = await _backupService.createAndShareBackup();

      if (!mounted) return;

      final now = result.timestamp;
      final newTime =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_last_sync', newTime);
      await prefs.setString('backup_status', l.backupStatusSynced);
      await prefs.setInt('backup_records_count', result.recordCount);

      setState(() {
        _lastSync = newTime;
        _syncStatus = l.backupStatusSynced;
        _pendingChanges = 0;
        _recordsCount = result.recordCount;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(l.backupSuccessMsg),
          backgroundColor: AppColors.success,
        ),
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  // ── Restore placeholder ────────────────────────────────────────────────────

  void _triggerRestore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select a backup file to restore from.')),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _getStatusColor() {
    final l = AppLocalizations.of(context)!;
    if (_syncStatus == l.backupStatusSynced) return AppColors.success;
    if (_syncStatus == l.backupStatusOffline) return AppColors.warning;
    if (_syncStatus == l.backupStatusFailed) return AppColors.danger;
    return AppColors.primary;
  }

  Widget _buildSectionShell(
    String title,
    List<Widget> children,
    Color outlineColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outlineColor),
      ),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: true,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final borderCol = cs.outlineVariant.withValues(alpha: 0.5);

    final freqMap = {
      'Real-time': l.backupFreqRealtime,
      'Every 15 minutes': l.backupFreq15m,
      'Hourly': l.backupFreqHourly,
      'Daily': l.backupFreqDaily,
      'Weekly': l.backupFreqWeekly,
    };

    // Display email: use Firebase Auth email, fallback to placeholder
    final displayEmail = _userEmail.isNotEmpty
        ? _userEmail
        : 'user@enterprise.com';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.backupSyncTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── Dashboard Overview ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.backupSyncStatusOverview,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isBackingUp ? l.backupStatusSyncing : _syncStatus,
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.backupLastSync),
                    Text(
                      _lastSync,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.backupPendingChanges),
                    Text(
                      '$_pendingChanges',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.backupRecordsCount),
                    Text(
                      '$_recordsCount',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Manual Controls ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isBackingUp ? null : _triggerBackup,
              icon: _isBackingUp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: const SizedBox.shrink(),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(l.backupBtnBackupNow),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _triggerRestore,
              icon: const Icon(Icons.restore_rounded),
              label: Text(l.backupBtnRestore),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Auto Sync Configuration ─────────────────────────────────────
          _buildSectionShell(l.backupAutoSettings, [
            SwitchListTile(
              title: Text(l.backupEnableAuto),
              value: _autoSync,
              onChanged: (v) {
                setState(() => _autoSync = v);
                _saveToggle('backup_auto', v);
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: Text(l.backupWifiOnly),
              value: _wifiOnly,
              onChanged: (v) {
                setState(() => _wifiOnly = v);
                _saveToggle('backup_wifi', v);
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: Text(l.backupSyncOnLaunch),
              value: _launchSync,
              onChanged: (v) {
                setState(() => _launchSync = v);
                _saveToggle('backup_launch', v);
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: Text(l.backupBackgroundSync),
              value: _backgroundSync,
              onChanged: (v) {
                setState(() => _backgroundSync = v);
                _saveToggle('backup_bg', v);
              },
            ),
          ], borderCol),

          // ── Policy Engines ──────────────────────────────────────────────
          _buildSectionShell(l.backupFrequencyPolicy, [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _frequency,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: freqMap.keys
                    .map(
                      (k) =>
                          DropdownMenuItem(value: k, child: Text(freqMap[k]!)),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => _frequency = v!);
                  _saveString('backup_frequency', v!);
                },
              ),
            ),
          ], borderCol),

          // ── Conflict Strategy ───────────────────────────────────────────
          _buildSectionShell(l.backupConflictRes, [
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: Text(l.backupConflictLocal),
              // ignore: deprecated_member_use
              value: 'Keep Local Version',
              // ignore: deprecated_member_use
              groupValue: _conflictStrategy,
              // ignore: deprecated_member_use
              onChanged: (v) {
                setState(() => _conflictStrategy = v!);
                _saveString('backup_conflict', v!);
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: Text(l.backupConflictServer),
              // ignore: deprecated_member_use
              value: 'Keep Server Version',
              // ignore: deprecated_member_use
              groupValue: _conflictStrategy,
              // ignore: deprecated_member_use
              onChanged: (v) {
                setState(() => _conflictStrategy = v!);
                _saveString('backup_conflict', v!);
              },
            ),
          ], borderCol),

          // ── Scopes Selectors ────────────────────────────────────────────
          _buildSectionShell(l.backupDataScope, [
            ..._scopes.keys.map((k) {
              String title = k;
              if (k == 'Assets') title = l.backupScopeAssets;
              if (k == 'Contracts') title = l.backupScopeContracts;
              if (k == 'Tickets') title = l.backupScopeTickets;
              if (k == 'Settings') title = l.backupScopeSettings;
              if (k == 'Audit Logs') title = l.backupScopeAudit;

              return CheckboxListTile(
                title: Text(title),
                value: _scopes[k],
                onChanged: (v) {
                  setState(() => _scopes[k] = v!);
                  _saveScopes();
                },
              );
            }),
          ], borderCol),

          // ── Cloud Provider ──────────────────────────────────────────────
          _buildSectionShell(l.backupCloudProvider, [
            ListTile(
              leading: const Icon(
                Icons.email_rounded,
                color: AppColors.primary,
              ),
              title: Text(l.backupStorageType),
              subtitle: Text(
                '${l.backupTypeCloud} – $displayEmail',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _userEmail.isNotEmpty
                  ? Chip(
                      label: const Text('Active'),
                      backgroundColor: AppColors.success.withValues(
                        alpha: 0.12,
                      ),
                      labelStyle: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                      ),
                      side: BorderSide.none,
                    )
                  : OutlinedButton(
                      onPressed: () {},
                      child: Text(l.backupBtnDisconnect),
                    ),
            ),
          ], borderCol),

          // ── Backup History ──────────────────────────────────────────────
          _buildSectionShell(l.backupHistory, [
            if (_lastSync == 'Never')
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text(l.backupHistoryEmpty)),
              )
            else
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(_lastSync),
                subtitle: Text('$_recordsCount records – Success'),
                trailing: TextButton(
                  onPressed: _triggerRestore,
                  child: Text(l.backupBtnRestore),
                ),
              ),
          ], borderCol),

          const SizedBox(height: 16),

          // ── Security Notice ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.security_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.backupSecurityNotice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.backupSecurityDesc,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
