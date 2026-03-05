import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:assets_management/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      debugPrint('Failed to get package info: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(
          l.settingsAboutApp,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // ── Header Section ──────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l.appTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${l.aboutAppVersion} $_version • ${l.aboutAppBuild} $_buildNumber',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Description Section ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      l.aboutAppDescription,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.7,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Information Section ─────────────────────────────────────────
                  _buildSectionHeader(cs, l.aboutAppCompany),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    cs,
                    children: [
                      _buildInfoTile(
                        context,
                        icon: Icons.business_rounded,
                        title: l.aboutAppCompany,
                        trailing: 'WorldAssets Group',
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildInfoTile(
                        context,
                        icon: Icons.email_outlined,
                        title: l.aboutAppSupportEmail,
                        trailing: 'support@worldassets.com',
                        isSelectable: true,
                        trailingColor: AppColors.primary,
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildInfoTile(
                        context,
                        icon: Icons.language_rounded,
                        title: l.aboutAppWebsite,
                        trailingIcon: Icons.open_in_new_rounded,
                        onTap: () => _launchUrl('https://worldassets.com'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Legal Section ───────────────────────────────────────────────
                  _buildSectionHeader(cs, 'Legal'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    cs,
                    children: [
                      _buildInfoTile(
                        context,
                        title: l.aboutAppPrivacyPolicy,
                        trailingIcon: Icons.arrow_forward_ios_rounded,
                        onTap: () {
                          _launchUrl('https://worldassets.com/privacy');
                        },
                      ),
                      const Divider(height: 1, indent: 20),
                      _buildInfoTile(
                        context,
                        title: l.aboutAppTermsAndConditions,
                        trailingIcon: Icons.arrow_forward_ios_rounded,
                        onTap: () {
                          _launchUrl('https://worldassets.com/terms');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // ── Copyright ───────────────────────────────────────────────────
                  Text(
                    l.aboutAppCopyright,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme cs, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: cs.primary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    IconData? icon,
    required String title,
    String? trailing,
    IconData? trailingIcon,
    VoidCallback? onTap,
    bool isSelectable = false,
    Color? trailingColor,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null)
              isSelectable
                  ? SelectableText(
                      trailing,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: trailingColor ?? theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Text(
                      trailing,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: trailingColor ?? theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            if (trailingIcon != null)
              Icon(
                trailingIcon,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
