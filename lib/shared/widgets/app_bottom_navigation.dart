import 'package:clickable_animated_bottom_nav_bar/animated_bottom_nav_bar.dart';
import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onItemSelected,
  });

  final int currentIndex;
  final ValueChanged<int>? onItemSelected;

  static const _icons = [
    Icons.grid_view_rounded,
    Icons.chat_sharp,
    Icons.calendar_month,
    Icons.notifications_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBottomNavBar(
      icons: _icons,
      currentIndex: currentIndex,
      onTap: (index) {
        if (onItemSelected != null) {
          onItemSelected!(index);
        } else {
          _handleNavigation(context, index);
        }
      },
      backgroundColor: theme.colorScheme.surface,
      iconActiveColor: AppColors.secondary,
      iconInactiveColor: AppColors.primaryDark,
      containerActiveColor: AppColors.background,
      height: 68,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    final navigator = Navigator.of(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    String? routeName;
    switch (index) {
      case 0:
        routeName = AppRoutes.dashboard;
        break;
      case 1:
        routeName = AppRoutes.chatList;
        break;
      default:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Coming soon'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 1),
            ),
          );
        return;
    }

    if (currentRoute == routeName) {
      return;
    }

    navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
  }
}
