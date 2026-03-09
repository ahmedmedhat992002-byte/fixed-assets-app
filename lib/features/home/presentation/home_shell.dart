import 'package:assets_management/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
// ignore: depend_on_referenced_packages
import 'package:assets_management/l10n/app_localizations.dart';
import '../../../app/routes/app_routes.dart';
import '../../../features/notifications/presentation/notifications_screen.dart';
import '../../../features/schedule/presentation/schedule_screen.dart';
import '../../../shared/widgets/app_navigation_drawer.dart';
import '../../../shared/widgets/contact_support_sheet.dart';
import '../../assets/presentation/dashboard_screen.dart';
import '../../chat/domain/entities/chat_entities.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../notifications/data/notification_service.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/chat/chat_service.dart';
import 'package:provider/provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      // 0: Home / Dashboard
      KeyedSubtree(
        key: const ValueKey('dashboard_page'),
        child: ValueListenableBuilder<AdvancedDrawerValue>(
          valueListenable: _drawerController,
          builder: (context, value, _) => DashboardScreen(
            onNavigateToIntangible: () =>
                Navigator.of(context).pushNamed(AppRoutes.intangibleAssets),
            onOpenDrawer: _handleMenuButtonPressed,
            isDrawerVisible: value.visible,
          ),
        ),
      ),

      // 1: Chat
      KeyedSubtree(
        key: const ValueKey('chat_page'),
        child: ValueListenableBuilder<AdvancedDrawerValue>(
          valueListenable: _drawerController,
          builder: (context, value, _) => ChatListScreen(
            onTapChat: (ChatSummary chat) => Navigator.of(
              context,
            ).pushNamed(AppRoutes.chatDetail, arguments: chat),
            onOpenDrawer: _handleMenuButtonPressed,
            isDrawerVisible: value.visible,
          ),
        ),
      ),

      // 2: Schedule
      KeyedSubtree(
        key: const ValueKey('schedule_page'),
        child: ValueListenableBuilder<AdvancedDrawerValue>(
          valueListenable: _drawerController,
          builder: (context, value, _) => ScheduleScreen(
            onOpenDrawer: _handleMenuButtonPressed,
            isDrawerVisible: value.visible,
          ),
        ),
      ),

      // 3: Notifications
      KeyedSubtree(
        key: const ValueKey('notifications_page'),
        child: ValueListenableBuilder<AdvancedDrawerValue>(
          valueListenable: _drawerController,
          builder: (context, value, _) => NotificationsScreen(
            onOpenDrawer: _handleMenuButtonPressed,
            isDrawerVisible: value.visible,
          ),
        ),
      ),
    ];

    return AdvancedDrawer(
      controller: _drawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 350),
      backdropColor: AppColors.primary,
      childDecoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
      drawer: AppNavigationDrawer(
        onDashboard: () {
          _drawerController.hideDrawer();
          setState(() => _currentIndex = 0);
        },
        onAssets: () => _navigateAndClose(AppRoutes.assets),
        onAnalytics: () => _navigateAndClose(AppRoutes.analytics),
        onScanQr: () => _navigateAndClose(AppRoutes.qrScan),
        onMaintenance: () => _navigateAndClose(AppRoutes.maintenance),

        onFiles: () => _navigateAndClose(AppRoutes.files),
        onSettings: () => _navigateAndClose(AppRoutes.settings),
        onContactSupport: () {
          _drawerController.hideDrawer();
          ContactSupportSheet.show(context);
        },
        onAssetCategorySelected: _handleAssetCategorySelected,
        onAnalyticsCategorySelected: (cat) {
          _drawerController.hideDrawer();
          if (cat == 'Reports') {
            Navigator.of(context).pushNamed(AppRoutes.reports);
          } else {
            Navigator.of(context).pushNamed(AppRoutes.analytics);
          }
        },
      ),
      child: GestureDetector(
        onHorizontalDragStart: (_) => FocusScope.of(context).unfocus(),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: Scaffold(
            body: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: pages,
            ),
            bottomNavigationBar: _AppBottomNav(
              currentIndex: _currentIndex,
              onItemSelected: (i) {
                setState(() => _currentIndex = i);
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuButtonPressed() => _drawerController.showDrawer();

  void _navigateAndClose(String route) {
    _drawerController.hideDrawer();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Navigator.of(context).pushNamed(route);
    });
  }

  void _handleAssetCategorySelected(String category) {
    _drawerController.hideDrawer();
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      String? route;
      if (category == l.sectionIntangibleAssets) {
        route = AppRoutes.intangibleAssets;
      } else if (category == l.sectionVehicles) {
        route = AppRoutes.vehiclesList;
      } else if (category == l.sectionMachinery) {
        route = AppRoutes.machineryList;
      } else if (category == l.sectionComputerHardware) {
        route = AppRoutes.computerHardwareList;
      } else if (category == l.sectionComputerSoftware) {
        route = AppRoutes.computerSoftwareList;
      } else if (category == l.sectionFurniture) {
        route = AppRoutes.furnitureList;
      } else if (category == l.sectionFixedAssets) {
        route = AppRoutes.fixedAssetsList;
      } else if (category == l.sectionContracts) {
        route = AppRoutes.contractsList;
      }

      if (route != null) {
        if (!mounted) return;
        Navigator.of(context).pushNamed(route);
      } else {
        if (!mounted) return;
        _showSnackBar('$category coming soon');
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ── Custom 4-tab bottom navigation ───────────────────────────────────────────
class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.currentIndex,
    required this.onItemSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  List<_NavItem> _navItems(AppLocalizations l) => [
    _NavItem(icon: Icons.grid_view_rounded, label: l.navDashboard),
    _NavItem(icon: Icons.chat_outlined, label: l.navChat),
    _NavItem(icon: Icons.calendar_month_rounded, label: l.navSchedule),
    _NavItem(icon: Icons.notifications_outlined, label: l.navNotifications),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final items = _navItems(l);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              final isChat = i == 1;
              final isNotif = i == 3;
              final authService = context.read<AuthService>();
              final uid = authService.firebaseUser?.uid ?? '';

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onItemSelected(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              item.icon,
                              size: 24,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted.withValues(alpha: 0.8),
                            ),
                          ),
                          if (isChat)
                            StreamBuilder<int>(
                              stream: context
                                  .read<ChatService>()
                                  .getTotalUnreadCountStream(uid),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                if (count == 0) return const SizedBox.shrink();
                                return Positioned(
                                  top: -2,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (isNotif)
                            StreamBuilder<int>(
                              stream: context
                                  .read<NotificationService>()
                                  .getUnreadCountStream(),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                if (count == 0) return const SizedBox.shrink();
                                return Positioned(
                                  top: -2,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 11,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
