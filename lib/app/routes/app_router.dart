import 'package:flutter/material.dart';

import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/assets/presentation/add_asset_screen.dart';
import '../../features/assets/presentation/unified_asset_detail_screen.dart';
import '../../features/assets/presentation/assets_screen.dart';
import '../../features/assets/presentation/depreciation_schedule_screen.dart';
import '../../features/assets/presentation/intangible_assets_screen.dart';
import '../../features/assets/presentation/machinery_list_screen.dart';
import '../../features/assets/presentation/computer_hardware_list_screen.dart';
import '../../features/assets/presentation/computer_software_list_screen.dart';
import '../../features/assets/presentation/furniture_list_screen.dart';
import '../../features/assets/presentation/fixed_asset_list_screen.dart';
import '../../features/assets/presentation/vehicles_list_screen.dart';
import '../../features/assets/presentation/manual_search_screen.dart';
import '../../features/assets/presentation/warehouses_screen.dart';
import '../../features/assets/presentation/widgets/add_vehicle_sheet.dart';
import '../../features/contracts/presentation/contracts_list_screen.dart';
import '../../features/contracts/presentation/contract_detail_screen.dart';
import '../../features/contracts/presentation/add_contract_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import 'package:assets_management/features/location/presentation/real_time_tracking_screen.dart';
import 'package:assets_management/features/location/presentation/location_picker_screen.dart';
import '../../features/auth/presentation/account_details_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/new_password_screen.dart';
import '../../features/auth/presentation/registration_complete_screen.dart';
import '../../features/auth/presentation/reset_otp_screen.dart';
import '../../features/auth/presentation/set_password_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/chat/domain/entities/chat_entities.dart';
import '../../features/chat/presentation/chat_detail_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/location/presentation/location_setup_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/ereceipt/presentation/ereceipt_screen.dart';
import '../../features/qr_scan/presentation/qr_scan_screen.dart';
import '../../features/reports/presentation/report_detail_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/about_app_screen.dart';
import '../../features/settings/presentation/assets_settings_screen.dart';
import '../../features/compliance/presentation/compliance_settings_screen.dart';
import '../../features/compliance/presentation/audit_log_screen.dart';
import '../../features/legal/presentation/terms_conditions_screen.dart';
import '../../features/legal/presentation/dpa_screen.dart';
import '../../features/legal/presentation/privacy_policy_screen.dart';
import '../../features/support/presentation/support_dashboard_screen.dart';
import '../../features/support/presentation/create_ticket_screen.dart';
import '../../features/support/presentation/ticket_detail_screen.dart';
import '../../features/support/presentation/ticket_history_screen.dart';
import '../../features/support/presentation/sla_policy_screen.dart';
import '../../features/support/presentation/knowledge_base_screen.dart';
import '../../features/backup/presentation/backup_sync_screen.dart';
import '../../features/files/presentation/files_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/transactions/presentation/transactions_list_screen.dart';
import '../../features/settings/presentation/user_management_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'package:assets_management/app/routes/app_routes.dart';
import 'package:assets_management/core/models/receipt_data.dart';
import 'package:assets_management/core/sync/models/asset_local.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Splash & Onboarding ──────────────────────────────────────────────
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (context) => SplashScreen(
            onFinished: () => Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.onboarding),
          ),
        );

      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (context) => OnboardingScreen(
            onFinished: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.login),
          ),
        );

      // ── Auth ─────────────────────────────────────────────────────────────
      case AppRoutes.login:
        return MaterialPageRoute(builder: (context) => const LoginScreen());

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (context) => ForgotPasswordScreen(
            onSendOtp: () =>
                Navigator.of(context).pushNamed(AppRoutes.resetOtp),
          ),
        );

      case AppRoutes.resetOtp:
        return MaterialPageRoute(
          builder: (context) => ResetOtpScreen(
            onVerify: () =>
                Navigator.of(context).pushNamed(AppRoutes.newPassword),
            onResend: () {},
          ),
        );

      case AppRoutes.newPassword:
        return MaterialPageRoute(
          builder: (context) => NewPasswordScreen(
            onConfirm: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false),
          ),
        );

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (context) => const SignUpScreen());

      case AppRoutes.verifyEmail:
        return MaterialPageRoute(
          builder: (context) => const VerifyEmailScreen(),
        );

      case AppRoutes.setPassword:
        return MaterialPageRoute(
          builder: (context) => SetPasswordScreen(
            onNext: () =>
                Navigator.of(context).pushNamed(AppRoutes.accountDetails),
          ),
        );

      case AppRoutes.accountDetails:
        return MaterialPageRoute(
          builder: (context) => AccountDetailsScreen(
            onFinish: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.registrationComplete,
              (route) => false,
            ),
          ),
        );

      case AppRoutes.registrationComplete:
        return MaterialPageRoute(
          builder: (context) => RegistrationCompleteScreen(
            onGoToLogin: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false),
          ),
        );

      // ── Main App ─────────────────────────────────────────────────────────
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const HomeShell());

      // ── Assets ───────────────────────────────────────────────────────────
      case AppRoutes.assets:
        return MaterialPageRoute(builder: (_) => const AssetsScreen());

      case AppRoutes.intangibleAssets:
        return MaterialPageRoute(
          builder: (context) => IntangibleAssetsScreen(),
        );

      case AppRoutes.depreciationSchedule:
        final asset = settings.arguments as AssetLocal;
        return MaterialPageRoute(
          builder: (context) => DepreciationScheduleScreen(asset: asset),
        );

      case AppRoutes.assetDetail:
      case AppRoutes.intangibleAssetDetail:
      case AppRoutes.vehicleDetail:
      case AppRoutes.machineryDetail:
      case AppRoutes.computerHardwareDetail:
      case AppRoutes.computerSoftwareDetail:
      case AppRoutes.furnitureDetail:
      case AppRoutes.fixedAssetDetail:
        final args = settings.arguments;
        AssetLocal? asset;

        if (args is AssetLocal) {
          asset = args;
        } else if (args is Map<String, dynamic>) {
          // Attempt to construct from map or name if possible,
          // though usually these routes expect an AssetLocal now.
          asset = AssetLocal(
            id: args['id'] ?? 'temp-id',
            companyId: '',
            name: args['name'] ?? args['assetName'] ?? 'Asset',
            category: args['category'] ?? 'General',
            status: 'Active',
            purchasePrice: 0.0,
            currentValue: 0.0,
            depreciationMethod: 'None',
            version: 1,
            updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          );
        } else if (args is String) {
          asset = AssetLocal(
            id: 'temp-id',
            companyId: '',
            name: args,
            category: 'General',
            status: 'Active',
            purchasePrice: 0.0,
            currentValue: 0.0,
            depreciationMethod: 'None',
            version: 1,
            updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          );
        }

        if (asset != null) {
          return MaterialPageRoute(
            builder: (_) => UnifiedAssetDetailScreen(asset: asset!),
          );
        }

        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Asset data missing'))),
        );

      case AppRoutes.addAsset:
        String category = 'Machinery';
        String? assetName;
        AssetLocal? asset;
        if (settings.arguments is String) {
          category = settings.arguments as String;
        } else if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          category = args['category'] ?? 'Assets';
          assetName = args['assetName'];
        } else if (settings.arguments is AssetLocal) {
          asset = settings.arguments as AssetLocal;
          category = asset.category;
        }
        return MaterialPageRoute(
          builder: (_) => AddAssetScreen(
            category: category,
            assetName: assetName,
            asset: asset,
          ),
        );

      case AppRoutes.vehiclesList:
        return MaterialPageRoute(
          builder: (context) => VehiclesListScreen(
            onVehicleTap: (asset) => Navigator.of(
              context,
            ).pushNamed(AppRoutes.vehicleDetail, arguments: asset),
            onAddVehicle: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddVehicleSheet(),
              );
            },
          ),
        );

      case AppRoutes.machineryList:
        return MaterialPageRoute(
          builder: (context) => const MachineryListScreen(),
        );

      case AppRoutes.computerHardwareList:
        return MaterialPageRoute(
          builder: (_) => const ComputerHardwareListScreen(),
        );

      case AppRoutes.computerSoftwareList:
        return MaterialPageRoute(
          builder: (_) => const ComputerSoftwareListScreen(),
        );

      case AppRoutes.furnitureList:
        return MaterialPageRoute(builder: (_) => const FurnitureListScreen());

      case AppRoutes.fixedAssetsList:
        return MaterialPageRoute(builder: (_) => const FixedAssetsListScreen());

      case AppRoutes.warehouses:
        return MaterialPageRoute(builder: (_) => const WarehousesScreen());
      case AppRoutes.contractsList:
        return MaterialPageRoute(builder: (_) => const ContractsListScreen());

      case AppRoutes.contractDetail:
        final args = settings.arguments;
        String cName = 'Contract';
        if (args is String) {
          cName = args;
        } else if (args is Map<String, dynamic>) {
          cName = args['name'] ?? args['contractName'] ?? 'Contract';
        }
        return MaterialPageRoute(
          builder: (_) => ContractDetailScreen(contractName: cName),
        );

      case AppRoutes.addContract:
        return MaterialPageRoute(builder: (_) => const AddContractScreen());

      // ── Chat ─────────────────────────────────────────────────────────────
      case AppRoutes.chatList:
        return MaterialPageRoute(
          builder: (context) => ChatListScreen(
            onTapChat: (chat) => Navigator.of(
              context,
            ).pushNamed(AppRoutes.chatDetail, arguments: chat),
          ),
        );

      case AppRoutes.chatDetail:
        final args = settings.arguments;
        ChatSummary? chat;
        if (args is ChatSummary) {
          chat = args;
        } else if (args is Map<String, dynamic>) {
          chat = ChatSummary(
            id: args['id'] ?? args['chatId'] ?? '1',
            name: args['name'] ?? args['contactName'] ?? 'Chat',
            lastMessagePreview: '',
            timestamp: '',
            isPinned: false,
            status: ChatStatus.online,
            avatarUrl: '',
            isTyping: false,
            unreadCount: 0,
          );
        }
        return MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chat?.id ?? '1',
            contactName: chat?.name ?? 'Chat',
          ),
        );

      // ── Analytics ────────────────────────────────────────────────────────
      case AppRoutes.analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());

      // ── Reports ──────────────────────────────────────────────────────────
      case AppRoutes.reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());

      case AppRoutes.reportDetail:
        // ReportDetailScreen is typically pushed directly from ReportsScreen
        // with explicit named params. This named-route handler provides
        // a fallback that shows a generic report detail page.
        return MaterialPageRoute(
          builder: (_) => const ReportDetailScreen(
            title: 'Report',
            type: 'General',
            date: '-',
            period: '-',
            icon: Icons.assessment_rounded,
          ),
        );

      // ── Notifications ────────────────────────────────────────────────────
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      // ── Schedule ────────────────────────────────────────────────────────
      case AppRoutes.schedule:
        return MaterialPageRoute(builder: (_) => const ScheduleScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      // ── QR Scan ──────────────────────────────────────────────────────────
      case AppRoutes.qrScan:
        return MaterialPageRoute(builder: (_) => const QrScanScreen());

      // ── Maintenance ────────────────────────────────────────────────────────
      case AppRoutes.maintenance:
        return MaterialPageRoute(builder: (_) => const MaintenanceScreen());

      case AppRoutes.transactions:
        return MaterialPageRoute(
          builder: (_) => const TransactionsListScreen(),
        );

      // ── Settings & Legal ─────────────────────────────────────────────────────────
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.aboutApp:
        return MaterialPageRoute(builder: (_) => const AboutAppScreen());
      case AppRoutes.assetsSettings:
        return MaterialPageRoute(builder: (_) => const AssetsSettingsScreen());
      case AppRoutes.complianceSettings:
        return MaterialPageRoute(
          builder: (_) => const ComplianceSettingsScreen(),
        );
      case AppRoutes.auditLogs:
        return MaterialPageRoute(builder: (_) => const AuditLogScreen());
      case AppRoutes.termsConditions:
        return MaterialPageRoute(builder: (_) => const TermsConditionsScreen());
      case AppRoutes.dpa:
        return MaterialPageRoute(builder: (_) => const DpaScreen());
      case AppRoutes.privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case AppRoutes.backupSync:
        return MaterialPageRoute(builder: (_) => const BackupSyncScreen());

      // ── Support ───────────────────────────────────────────────────────────
      case AppRoutes.supportDashboard:
        return MaterialPageRoute(
          builder: (_) => const SupportDashboardScreen(),
        );
      case AppRoutes.createTicket:
        return MaterialPageRoute(builder: (_) => const CreateTicketScreen());
      case AppRoutes.ticketDetail:
        // Support dynamic rendering by passing args if supplied, else gracefully fall back
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticketMap: args),
        );
      case AppRoutes.ticketHistory:
        return MaterialPageRoute(builder: (_) => const TicketHistoryScreen());
      case AppRoutes.slaPolicy:
        return MaterialPageRoute(builder: (_) => const SlaPolicyScreen());
      case AppRoutes.knowledgeBase:
        return MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen());

      // ── Files ─────────────────────────────────────────────────────────────
      case AppRoutes.files:
        return MaterialPageRoute(builder: (_) => const FilesScreen());

      case AppRoutes.userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());

      // ── Location (legacy) ────────────────────────────────────────────────
      case AppRoutes.locationSetup:
        return MaterialPageRoute(
          builder: (context) => LocationSetupScreen(
            onSaveAndContinue: () =>
                Navigator.of(context).pushNamed(AppRoutes.dashboard),
          ),
        );

      case AppRoutes.locationConfirm:
        return MaterialPageRoute(
          builder: (context) => const LocationSetupScreen(),
        );

      case AppRoutes.manualSearch:
        final query = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ManualSearchScreen(initialQuery: query),
        );

      case AppRoutes.eReceipt:
        final data = settings.arguments as ReceiptData? ?? ReceiptData.mock();
        return MaterialPageRoute(builder: (_) => EReceiptScreen(data: data));

      case AppRoutes.realTimeTracking:
        final args = settings.arguments;
        if (args is! AssetLocal) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid Asset for Tracking')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => RealTimeTrackingScreen(asset: args),
        );

      case AppRoutes.locationPicker:
        return MaterialPageRoute(builder: (_) => const LocationPickerScreen());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
