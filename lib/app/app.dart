import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:assets_management/core/auth/auth_service.dart';
import 'package:assets_management/core/auth/auth_wrapper.dart';
import 'package:assets_management/core/auth/presence_observer.dart';
import 'package:assets_management/core/assets/asset_service.dart';
import 'package:assets_management/core/contracts/contract_service.dart';
import 'package:assets_management/core/dashboard/dashboard_service.dart';
import 'package:assets_management/core/analytics/analytics_service.dart';
import 'package:assets_management/core/locale/locale_controller.dart';
import 'package:assets_management/core/theme/app_theme.dart';
import 'package:assets_management/core/theme/theme_controller.dart';
import 'package:assets_management/core/transactions/transaction_service.dart';
import 'package:assets_management/core/files/files_service.dart';
import 'package:assets_management/core/user_management/user_management_service.dart';
import 'package:assets_management/core/maintenance/maintenance_service.dart';
import 'package:assets_management/core/chat/chat_service.dart';
import 'package:assets_management/features/notifications/data/notification_service.dart';
import 'package:assets_management/core/chat/call_service.dart';
import 'package:assets_management/core/timeline/timeline_service.dart';
import 'package:assets_management/core/approvals/approval_service.dart';
import 'package:assets_management/features/settings/data/notification_settings_controller.dart';
import 'package:assets_management/features/settings/data/security_settings_controller.dart';
import 'package:assets_management/app/routes/app_router.dart';

// ignore: depend_on_referenced_packages
import 'package:assets_management/l10n/app_localizations.dart';

/// Root widget.
///
/// All three services (AuthService, LocaleController, ThemeController) are
/// created and initialized in main() BEFORE runApp() is called, so there is
/// zero risk of any Provider.create() callback firing before Firebase or Hive
/// is ready. Each service is registered with ChangeNotifierProvider.value()
/// because the instance already exists — no lazy factory needed.
class App extends StatelessWidget {
  const App({
    super.key,
    required this.authService,
    required this.localeController,
    required this.themeController,
    required this.notificationSettingsController,
    required this.securitySettingsController,
  });

  final AuthService authService;
  final LocaleController localeController;
  final ThemeController themeController;
  final NotificationSettingsController notificationSettingsController;
  final SecuritySettingsController securitySettingsController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // .value() — instance already constructed & initialized in main().
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<NotificationSettingsController>.value(
          value: notificationSettingsController,
        ),
        ChangeNotifierProvider<SecuritySettingsController>.value(
          value: securitySettingsController,
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        ChangeNotifierProvider<TransactionService>(
          create: (_) => TransactionService(),
        ),
        ChangeNotifierProvider<FilesService>(create: (_) => FilesService()),
        ChangeNotifierProxyProvider2<
          TransactionService,
          NotificationService,
          AssetService
        >(
          create: (_) => AssetService(),
          update: (_, trans, notif, asset) => asset!
            ..setTransactionService(trans)
            ..setNotificationService(notif),
        ),
        ProxyProvider<NotificationService, ContractService>(
          create: (_) => ContractService(),
          update: (_, notif, contract) =>
              contract!..setNotificationService(notif),
        ),
        ChangeNotifierProvider<DashboardService>(
          create: (_) => DashboardService(),
        ),
        ChangeNotifierProvider<AnalyticsService>(
          create: (_) => AnalyticsService(),
        ),
        Provider<UserManagementService>(create: (_) => UserManagementService()),
        ChangeNotifierProxyProvider<NotificationService, ChatService>(
          create: (_) => ChatService(),
          update: (_, notif, chat) => chat!..setNotificationService(notif),
        ),
        ChangeNotifierProxyProvider<NotificationService, MaintenanceService>(
          create: (_) => MaintenanceService(),
          update: (_, notif, maint) => maint!..setNotificationService(notif),
        ),
        ChangeNotifierProvider<CallService>(create: (_) => CallService()),
        ChangeNotifierProvider<TimelineService>(create: (_) => TimelineService()),
        ChangeNotifierProvider<ApprovalService>(create: (_) => ApprovalService()),
      ],
      child: Consumer2<LocaleController, ThemeController>(
        builder: (_, localeCtrl, themeCtrl, __) => PresenceObserver(
          child: MaterialApp(
            title: 'WorldAssets',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeCtrl.themeMode,
            locale: localeCtrl.locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // AuthWrapper listens to AuthService.status and renders
            // LoadingPage / LoginScreen / VerifyEmailScreen / HomeShell.
            home: const AuthWrapper(),
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        ),
      ),
    );
  }
}
