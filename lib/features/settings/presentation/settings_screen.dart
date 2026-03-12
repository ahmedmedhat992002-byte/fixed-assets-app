// ignore_for_file: deprecated_member_use
import 'package:assets_management/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/logout_button.dart';
import 'notification_settings_screen.dart';
import 'language_screen.dart';
import 'security_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../app/routes/app_routes.dart';
import '../../../core/profile/profile_service.dart';
import '../../../core/search/global_search_delegate.dart';
import '../../../core/utils/data_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Account fields handled internally by _AccountTab

  // Business fields
  final _businessNameCtrl = TextEditingController(text: 'Kaluma Tech');
  final _industryCtrl = TextEditingController(text: 'Clothing');
  final _locationCtrl = TextEditingController(text: 'Cairo');
  final _bizEmailCtrl = TextEditingController(text: 'markalex@gmail.com');
  final _bizPhoneCtrl = TextEditingController(text: '717522604');
  final _valuationCtrl = TextEditingController(text: 'LE 18,000,000');
  final _employeesCtrl = TextEditingController(text: '550');
  String _bizPhoneCode = '+254';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessNameCtrl.dispose();
    _industryCtrl.dispose();
    _locationCtrl.dispose();
    _bizEmailCtrl.dispose();
    _bizPhoneCtrl.dispose();
    _valuationCtrl.dispose();
    _employeesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
            onPressed: () {
              showSearch(context: context, delegate: GlobalSearchDelegate());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    tabs: [
                      Tab(text: AppLocalizations.of(context)!.settingsAccount),
                      Tab(text: AppLocalizations.of(context)!.settingsBusiness),
                      Tab(
                        text: AppLocalizations.of(context)!.settingsGeneralTab,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.settingsTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const _AccountTab(),
                _BusinessTab(
                  businessNameCtrl: _businessNameCtrl,
                  industryCtrl: _industryCtrl,
                  locationCtrl: _locationCtrl,
                  bizEmailCtrl: _bizEmailCtrl,
                  bizPhoneCtrl: _bizPhoneCtrl,
                  valuationCtrl: _valuationCtrl,
                  employeesCtrl: _employeesCtrl,
                  bizPhoneCode: _bizPhoneCode,
                  onBizPhoneCodeChanged: (v) =>
                      setState(() => _bizPhoneCode = v ?? _bizPhoneCode),
                ),
                const _GeneralTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Account Tab ──────────────────────────────────────────────────────────────
class _AccountTab extends StatefulWidget {
  const _AccountTab();

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  // Controllers initialized immediately from synchronous Auth data
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  String _phoneCode = '+254';
  static const _phoneCodes = ['+254', '+20', '+1', '+44', '+971'];

  String? _photoUrl;
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    // Compute initial values synchronously from FirebaseAuth — no waiting
    String firstName = '';
    String lastName = '';
    final displayName = DataUtils.asString(user?.displayName).trim();
    if (displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      firstName = parts.first;
      if (parts.length > 1) lastName = parts.sublist(1).join(' ');
    }

    _firstNameCtrl = TextEditingController(text: firstName);
    _lastNameCtrl = TextEditingController(text: lastName);
    _positionCtrl = TextEditingController();
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController();

    // After the form is shown, fetch Firestore data and update controllers
    if (user != null) {
      ProfileService().getProfileStream(user.uid).first.then((profile) {
        if (!mounted || profile == null) return;

        if (profile.firstName.isNotEmpty) {
          _firstNameCtrl.text = profile.firstName;
        }
        if (profile.lastName.isNotEmpty) {
          _lastNameCtrl.text = profile.lastName;
        }
        if (profile.position.isNotEmpty) {
          _positionCtrl.text = profile.position;
        }
        if (profile.phone.isNotEmpty) {
          _phoneCtrl.text = profile.phone;
        }
        if (profile.phoneCode.isNotEmpty) {
          if (_phoneCodes.contains(profile.phoneCode)) {
            setState(() => _phoneCode = profile.phoneCode);
          }
        }
        if (profile.photoUrl.isNotEmpty) {
          setState(() => _photoUrl = profile.photoUrl);
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      String? finalPhotoUrl = _photoUrl;

      // 1. Upload new image if selected
      if (_selectedImage != null) {
        finalPhotoUrl = await ProfileService().uploadProfilePhoto(
          user.uid,
          _selectedImage!,
          _selectedImage!.path.split('/').last,
        );
      }

      // 2. Update profile data
      await ProfileService().updateProfile(
        uid: user.uid,
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        position: _positionCtrl.text,
        phone: _phoneCtrl.text,
        phoneCode: _phoneCode,
        photoUrl: finalPhotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {
          _photoUrl = finalPhotoUrl;
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _positionCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Form is rendered immediately — no spinner, no waiting
    return _AccountForm(
      firstNameCtrl: _firstNameCtrl,
      lastNameCtrl: _lastNameCtrl,
      positionCtrl: _positionCtrl,
      emailCtrl: _emailCtrl,
      phoneCtrl: _phoneCtrl,
      phoneCode: _phoneCode,
      phoneCodes: _phoneCodes,
      onPhoneCodeChanged: (v) {
        if (v != null) setState(() => _phoneCode = v);
      },
      photoUrl: _photoUrl,
      selectedImage: _selectedImage,
      onPickImage: _pickImage,
      onSave: _saveProfile,
      isSaving: _isSaving,
    );
  }
}

class _AccountForm extends StatefulWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController positionCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final String phoneCode;
  final List<String> phoneCodes;
  final ValueChanged<String?> onPhoneCodeChanged;

  final String? photoUrl;
  final File? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback onSave;
  final bool isSaving;

  const _AccountForm({
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.positionCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.phoneCode,
    required this.phoneCodes,
    required this.onPhoneCodeChanged,
    this.photoUrl,
    this.selectedImage,
    required this.onPickImage,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  // NOTE: controllers are owned by _AccountTabState, do NOT dispose them here.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top: Profile photo
          GestureDetector(
            onTap: widget.onPickImage,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
                image: widget.selectedImage != null
                    ? DecorationImage(
                        image: FileImage(widget.selectedImage!),
                        fit: BoxFit.cover,
                      )
                    : (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(widget.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child:
                  (widget.selectedImage == null &&
                      (widget.photoUrl == null || widget.photoUrl!.isEmpty))
                  ? Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: cs.secondary,
                        size: 60,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onPickImage,
            child: Text(
              AppLocalizations.of(context)!.settingsAddProfilePhoto,
              style: TextStyle(
                color: cs.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Form fields
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(AppLocalizations.of(context)!.settingsFirstName),
              _RoundedInput(
                controller: widget.firstNameCtrl,
                hint: 'First name',
              ),
              const SizedBox(height: 16),
              _FieldLabel(AppLocalizations.of(context)!.settingsLastName),
              _RoundedInput(controller: widget.lastNameCtrl, hint: 'Last name'),
              const SizedBox(height: 16),
              _FieldLabel(
                AppLocalizations.of(context)!.settingsCurrentPosition,
              ),
              _RoundedInput(
                controller: widget.positionCtrl,
                hint: 'Current Position',
              ),
              const SizedBox(height: 16),
              _FieldLabel(AppLocalizations.of(context)!.settingsEmail),
              _RoundedInput(
                controller: widget.emailCtrl,
                hint: 'email@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _FieldLabel(AppLocalizations.of(context)!.settingsPhoneNumber),
              Row(
                children: [
                  // Dropdown - No fixed width container, use Flexible/Expanded
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.phoneCode,
                        dropdownColor: cs.surface,
                        items: widget.phoneCodes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: widget.onPhoneCodeChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundedInput(
                      controller: widget.phoneCtrl,
                      hint: 'Phone Number',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: cs.primary,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.isSaving ? null : widget.onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: widget.isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: const SizedBox.shrink(),
                    )
                  : Text(
                      AppLocalizations.of(context)!.settingsSave,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Business Tab ─────────────────────────────────────────────────────────────
class _BusinessTab extends StatelessWidget {
  const _BusinessTab({
    required this.businessNameCtrl,
    required this.industryCtrl,
    required this.locationCtrl,
    required this.bizEmailCtrl,
    required this.bizPhoneCtrl,
    required this.valuationCtrl,
    required this.employeesCtrl,
    required this.bizPhoneCode,
    required this.onBizPhoneCodeChanged,
  });

  final TextEditingController businessNameCtrl;
  final TextEditingController industryCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController bizEmailCtrl;
  final TextEditingController bizPhoneCtrl;
  final TextEditingController valuationCtrl;
  final TextEditingController employeesCtrl;
  final String bizPhoneCode;
  final ValueChanged<String?> onBizPhoneCodeChanged;

  static const _phoneCodes = ['+254', '+20', '+1', '+44', '+971'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Company logo
          GestureDetector(
            onTap: () {}, // Not implemented yet
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Center(
                child: Icon(Icons.image_rounded, color: cs.secondary, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.settingsCompanyLogo,
            style: TextStyle(
              color: cs.secondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Business details column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(AppLocalizations.of(context)!.settingsBusinessName),
              _RoundedInput(controller: businessNameCtrl, hint: 'Kaluma Tech'),
              const SizedBox(height: 16),
              _FieldLabel(AppLocalizations.of(context)!.settingsIndustry),
              _RoundedInput(controller: industryCtrl, hint: 'Clothing'),
              const SizedBox(height: 16),
              _FieldLabel(AppLocalizations.of(context)!.settingsLocation),
              _RoundedInput(controller: locationCtrl, hint: 'Cairo'),
              const SizedBox(height: 16),
              _FieldLabel(AppLocalizations.of(context)!.settingsBusinessEmail),
              _RoundedInput(
                controller: bizEmailCtrl,
                hint: 'markalex@gmail.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _FieldLabel(AppLocalizations.of(context)!.settingsBusinessNumber),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: bizPhoneCode,
                        dropdownColor: cs.surface,
                        items: _BusinessTab._phoneCodes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: onBizPhoneCodeChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundedInput(
                      controller: bizPhoneCtrl,
                      hint: '717522604',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: cs.primary,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldLabel(AppLocalizations.of(context)!.settingsValuation),
              _RoundedInput(
                controller: valuationCtrl,
                hint: 'LE 18,000,000',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _FieldLabel(AppLocalizations.of(context)!.settingsEmployees),
              _RoundedInput(
                controller: employeesCtrl,
                hint: '550',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Business Save Button (placeholder logic normally)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.settingsSave,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── General Tab ──────────────────────────────────────────────────────────────
class _GeneralTab extends StatelessWidget {
  const _GeneralTab();

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    return ListView(
      children: [
        _GeneralItem(
          icon: Icons.notifications_outlined,
          label: AppLocalizations.of(context)!.settingsNotification,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen(),
            ),
          ),
        ),
        _GeneralItem(
          icon: Icons.shield_outlined,
          label: AppLocalizations.of(context)!.settingsAppPreferences,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SecurityScreen())),
        ),
        _GeneralItem(
          icon: Icons.grid_view_rounded,
          label: AppLocalizations.of(context)!.settingsAssetsSettings,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.assetsSettings),
        ),
        _GeneralItem(
          icon: Icons.manage_accounts_outlined,
          label: AppLocalizations.of(context)!.settingsUserManagement,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.userManagement),
        ),
        _GeneralItem(
          icon: Icons.language_outlined,
          label: AppLocalizations.of(context)!.settingsLanguage,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LanguageScreen())),
        ),
        // Dark mode row with switch — connected to ThemeController
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.dark_mode_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.settingsDarkMode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: themeCtrl.isDark,
                onChanged: (_) => themeCtrl.toggle(),
              ),
            ],
          ),
        ),

        // Added Theme Color Selection
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Theme Color',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF78909C)),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: ThemeController.availableColors.length,
            itemBuilder: (context, index) {
              final color = ThemeController.availableColors[index];
              final isSelected = themeCtrl.colorIndex == index;
              return GestureDetector(
                onTap: () => themeCtrl.setPrimaryColorIndex(index),
                child: Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _GeneralItem(
          icon: Icons.admin_panel_settings_outlined,
          label: AppLocalizations.of(context)!.complianceSettingsTitle,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.complianceSettings),
        ),
        _GeneralItem(
          icon: Icons.support_agent_rounded,
          label: AppLocalizations.of(context)!.settingsSupportHelp,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.supportDashboard),
        ),
        _GeneralItem(
          icon: Icons.cloud_sync_rounded,
          label: AppLocalizations.of(context)!.settingsBackupSync,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.backupSync),
        ),
        _GeneralItem(
          icon: Icons.lock_outlined,
          label: AppLocalizations.of(context)!.settingsAboutApp,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.aboutApp),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: LogoutButton(style: LogoutButtonStyle.elevated),
        ),
      ],
    );
  }
}

class _GeneralItem extends StatelessWidget {
  const _GeneralItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 24, color: cs.onSurface),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _RoundedInput extends StatelessWidget {
  const _RoundedInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: cs.surfaceContainerLow,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary),
        ),
      ),
    );
  }
}
