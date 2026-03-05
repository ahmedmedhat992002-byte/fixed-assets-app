import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/profile/profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/logout_button.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/profile/models/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId});

  /// The ID of the user whose profile to display.
  /// If null, displays the current user's profile.
  final String? userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Stream<ProfileModel?>? _profileStream;

  @override
  void initState() {
    super.initState();
    final effectiveUid =
        widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUid != null) {
      _profileStream = ProfileService().getProfileStream(effectiveUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthService>().firebaseUser;

    // Provide a localized fallback just in case
    final l = AppLocalizations.of(context);
    final profileTitle = l?.navSettings ?? 'Profile';

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(profileTitle)),
        body: const Center(child: Text('Please log in to view your profile.')),
      );
    }

    final creationDate = user.metadata.creationTime;
    final dateStr = creationDate != null
        ? DateFormat.yMMMMd().format(creationDate)
        : 'Unknown';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(profileTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Avatar with a more premium look
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_rounded,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            StreamBuilder<ProfileModel?>(
              stream: _profileStream,
              builder: (context, snapshot) {
                String name = 'User';
                String position = '';
                String email = user.email ?? 'No email';

                if (snapshot.hasData && snapshot.data != null) {
                  final profile = snapshot.data!;
                  name = profile.fullName;
                  position = profile.position;
                  if (profile.email.isNotEmpty) email = profile.email;
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
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (position.isNotEmpty) ...[
                      Text(
                        position,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                'ID: ${user.uid}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                  fontSize: 10,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Profile info cards
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Account Created',
              value: dateStr,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.verified_user_rounded,
              label: 'Status',
              value: 'Active',
              valueColor: AppColors.success,
            ),

            const SizedBox(height: 48),

            // Actions
            if (widget.userId == null) ...[
              const SizedBox(
                width: double.infinity,
                child: LogoutButton(
                  style: LogoutButtonStyle.elevated,
                  label: 'Sign Out',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
