import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:assets_management/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/profile/profile_service.dart';
import '../../core/profile/models/profile_model.dart';
import 'logout_button.dart';

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({
    super.key,
    this.onDashboard,
    this.onAssets,
    this.onAnalytics,
    this.onScanQr,
    this.onMaintenance,
    this.onFiles,
    this.onSettings,
    this.onContactSupport,
    this.onAssetCategorySelected,
    this.onAnalyticsCategorySelected,
  });

  final VoidCallback? onDashboard;
  final VoidCallback? onAssets;
  final VoidCallback? onAnalytics;
  final VoidCallback? onScanQr;
  final VoidCallback? onMaintenance;
  final VoidCallback? onFiles;
  final VoidCallback? onSettings;
  final VoidCallback? onContactSupport;
  final ValueChanged<String>? onAssetCategorySelected;
  final ValueChanged<String>? onAnalyticsCategorySelected;

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  bool _assetsExpanded = false;
  bool _analyticsExpanded = false;

  List<String> _assetCategories(AppLocalizations l) => [
    l.sectionIntangibleAssets,
    l.sectionMachinery,
    l.sectionVehicles,
    l.sectionComputerHardware,
    l.sectionComputerSoftware,
    l.sectionFurniture,
    l.sectionFixedAssets,
    l.sectionContracts,
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Container(
        width: 280,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(onTap: widget.onSettings),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _SectionLabel(l.navWorkplace),
                  const SizedBox(height: 12),
                  _DrawerItem(
                    icon: Icons.grid_view_rounded,
                    label: l.navDashboard,
                    onTap: widget.onDashboard,
                  ),
                  const SizedBox(height: 12),
                  _AssetsSection(
                    expanded: _assetsExpanded,
                    highlighted: _assetsExpanded,
                    onToggle: () =>
                        setState(() => _assetsExpanded = !_assetsExpanded),
                    onViewAll: widget.onAssets,
                    categories: _assetCategories(l),
                    onCategorySelected:
                        widget.onAssetCategorySelected ?? (_) {},
                    assetsLabel: l.navAssets,
                  ),
                  const SizedBox(height: 18),
                  _AnalyticsSection(
                    expanded: _analyticsExpanded,
                    highlighted: _analyticsExpanded,
                    onToggle: () => setState(
                      () => _analyticsExpanded = !_analyticsExpanded,
                    ),
                    onViewAll: widget.onAnalytics,
                    onCategorySelected:
                        widget.onAnalyticsCategorySelected ?? (_) {},
                    analyticsLabel: l.navAnalytics,
                    reportsLabel: l.navReports,
                  ),
                  const SizedBox(height: 18),
                  _DrawerItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: l.navScanQr,
                    onTap: widget.onScanQr,
                  ),
                  const SizedBox(height: 18),
                  _DrawerItem(
                    icon: Icons.build_rounded,
                    label: l.navMaintenance,
                    onTap: widget.onMaintenance,
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel(l.navGeneral),
                  const SizedBox(height: 18),
                  _DrawerItem(
                    icon: Icons.folder_open_rounded,
                    label: l.navFiles,
                    onTap: widget.onFiles,
                  ),
                  const SizedBox(height: 18),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: l.navSettings,
                    onTap: widget.onSettings,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: LogoutButton(
                style: LogoutButtonStyle.listTile,
                label: 'Sign Out',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: widget.onContactSupport,
                  icon: const Icon(
                    Icons.headset_mic_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    l.navContactSupport,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Analytics Expandable Section ──────────────────────────────────────────────
class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.expanded,
    required this.onToggle,
    required this.onCategorySelected,
    required this.analyticsLabel,
    required this.reportsLabel,
    this.highlighted = false,
    this.onViewAll,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onCategorySelected;
  final bool highlighted;
  final VoidCallback? onViewAll;
  final String analyticsLabel;
  final String reportsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = highlighted
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.transparent;
    final fgColor = highlighted ? AppColors.secondary : Colors.white;

    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_chart_outlined_rounded,
                  color: fgColor,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    analyticsLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: fgColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: fgColor.withValues(alpha: 0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              children: [analyticsLabel, reportsLabel].map((sub) {
                return InkWell(
                  onTap: () => onCategorySelected(sub),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          sub,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Assets Expandable Section ─────────────────────────────────────────────────
class _AssetsSection extends StatelessWidget {
  const _AssetsSection({
    required this.expanded,
    required this.onToggle,
    required this.categories,
    required this.onCategorySelected,
    required this.assetsLabel,
    this.highlighted = false,
    this.onViewAll,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;
  final bool highlighted;
  final VoidCallback? onViewAll;
  final String assetsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundGradient = highlighted
        ? LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final fgColor = highlighted ? AppColors.secondary : Colors.white;

    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              gradient: backgroundGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: fgColor, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    assetsLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: fgColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: fgColor.withValues(alpha: 0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...categories.map(
                  (cat) => InkWell(
                    onTap: () => onCategorySelected(cat),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────
class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({this.onTap});
  final VoidCallback? onTap;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  Stream<ProfileModel?>? _profileStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _profileStream = ProfileService().getProfileStream(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: StreamBuilder<ProfileModel?>(
                stream: _profileStream,
                builder: (context, snapshot) {
                  String name = 'User';
                  String position = '';

                  if (snapshot.hasData && snapshot.data != null) {
                    final profile = snapshot.data!;
                    name = profile.fullName;
                    position = profile.position;
                  } else {
                    final authUser = FirebaseAuth.instance.currentUser;
                    final authProfile = context.read<AuthService>().profile;
                    name =
                        authProfile?.name ??
                        authUser?.displayName ??
                        (authUser?.email?.split('@').first ?? 'User');
                    if (name.isEmpty || name.toLowerCase() == 'user') {
                      name = authUser?.email?.split('@').first ?? 'User';
                    }
                  }

                  if (name.isNotEmpty && name.toLowerCase() != 'user') {
                    name = name[0].toUpperCase() + name.substring(1);
                  }

                  if (name.isEmpty) name = 'User';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (position.isNotEmpty)
                        Text(
                          position,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Colors.white.withValues(alpha: 0.74),
        letterSpacing: 0.2,
      ),
    );
  }
}

// ── Drawer Item ───────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const bgColor = Colors.transparent;
    const fgColor = Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(icon, color: fgColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: fgColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
