import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:assets_management/core/theme/app_colors.dart';
import 'package:assets_management/app/routes/app_routes.dart';
import 'package:assets_management/core/auth/auth_service.dart';
import 'package:assets_management/core/chat/chat_service.dart';
import 'package:assets_management/features/notifications/data/notification_service.dart';
import 'package:assets_management/l10n/app_localizations.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, this.currentIndex = 0});

  final int currentIndex;

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    final routes = [
      AppRoutes.dashboard,
      AppRoutes.chatList,
      AppRoutes.schedule,
      AppRoutes.notifications,
    ];

    Navigator.of(context).pushReplacementNamed(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final uid = authService.firebaseUser?.uid ?? '';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: l.navDashboard,
                isSelected: currentIndex == 0,
                onTap: () => _onItemTapped(context, 0),
              ),
              _NavItem(
                icon: currentIndex == 1
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                label: l.navChat,
                isSelected: currentIndex == 1,
                onTap: () => _onItemTapped(context, 1),
                badgeStream: context
                    .read<ChatService>()
                    .getTotalUnreadCountStream(uid),
                badgeColor: AppColors.warning,
              ),
              _NavItem(
                icon: currentIndex == 2
                    ? Icons.calendar_today_rounded
                    : Icons.calendar_today_outlined,
                label: l.navSchedule,
                isSelected: currentIndex == 2,
                onTap: () => _onItemTapped(context, 2),
              ),
              _NavItem(
                icon: currentIndex == 3
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                label: l.navNotifications,
                isSelected: currentIndex == 3,
                onTap: () => _onItemTapped(context, 3),
                badgeStream: context
                    .read<NotificationService>()
                    .getUnreadCountStream(),
                badgeColor: AppColors.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeStream,
    this.badgeColor,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Stream<int>? badgeStream;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 26,
                ),
                if (badgeStream != null)
                  StreamBuilder<int>(
                    stream: badgeStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: badgeColor ?? Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
