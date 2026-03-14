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
import '../../features/chat/presentation/forward_message_screen.dart';
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
import '../../features/approvals/presentation/approval_dashboard_screen.dart';
import 'package:assets_management/app/routes/app_routes.dart';
import 'package:assets_management/core/models/receipt_data.dart';
import 'package:assets_management/core/sync/models/asset_local.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Splash & Onboarding ──────────────────────────────────────────────
      case AppRoutes.splash:
        return _buildPageRoute(settings: settings, 
          builder: (context) => SplashScreen(
            onFinished: () => Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.onboarding),
          ),
        );

      case AppRoutes.onboarding:
        return _buildPageRoute(settings: settings, 
          builder: (context) => OnboardingScreen(
            onFinished: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.login),
          ),
        );

      // ── Auth ─────────────────────────────────────────────────────────────
      case AppRoutes.login:
        return _buildPageRoute(settings: settings, builder: (context) => const LoginScreen());

      case AppRoutes.forgotPassword:
        return _buildPageRoute(settings: settings, 
          builder: (context) => ForgotPasswordScreen(
            onSendOtp: () =>
                Navigator.of(context).pushNamed(AppRoutes.resetOtp),
          ),
        );

      case AppRoutes.resetOtp:
        return _buildPageRoute(settings: settings, 
          builder: (context) => ResetOtpScreen(
            onVerify: () =>
                Navigator.of(context).pushNamed(AppRoutes.newPassword),
            onResend: () {},
          ),
        );

      case AppRoutes.newPassword:
        return _buildPageRoute(settings: settings, 
          builder: (context) => NewPasswordScreen(
            onConfirm: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false),
          ),
        );

      case AppRoutes.signup:
        return _buildPageRoute(settings: settings, builder: (context) => const SignUpScreen());

      case AppRoutes.verifyEmail:
        return _buildPageRoute(settings: settings, 
          builder: (context) => const VerifyEmailScreen(),
        );

      case AppRoutes.setPassword:
        return _buildPageRoute(settings: settings, 
          builder: (context) => SetPasswordScreen(
            onNext: () =>
                Navigator.of(context).pushNamed(AppRoutes.accountDetails),
          ),
        );

      case AppRoutes.accountDetails:
        return _buildPageRoute(settings: settings, 
          builder: (context) => AccountDetailsScreen(
            onFinish: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.registrationComplete,
              (route) => false,
            ),
          ),
        );

      case AppRoutes.registrationComplete:
        return _buildPageRoute(settings: settings, 
          builder: (context) => RegistrationCompleteScreen(
            onGoToLogin: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false),
          ),
        );

      // ── Main App ─────────────────────────────────────────────────────────
      case AppRoutes.dashboard:
        return _buildPageRoute(settings: settings, builder: (_) => const HomeShell());

      // ── Assets ───────────────────────────────────────────────────────────
      case AppRoutes.assets:
        return _buildPageRoute(settings: settings, builder: (_) => const AssetsScreen());

      case AppRoutes.intangibleAssets:
        return _buildPageRoute(settings: settings, 
          builder: (context) => IntangibleAssetsScreen(),
        );

      case AppRoutes.depreciationSchedule:
        final asset = settings.arguments as AssetLocal;
        return _buildPageRoute(settings: settings, 
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
          return _buildPageRoute(settings: settings, 
            builder: (_) => UnifiedAssetDetailScreen(asset: asset!),
          );
        }

        return _buildPageRoute(settings: settings, 
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Asset data missing'))),
        );

      case AppRoutes.addAsset:
        String category = 'Machinery';
        String? assetName;
        String? barcode;
        AssetLocal? asset;
        if (settings.arguments is String) {
          category = settings.arguments as String;
        } else if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          category = args['category'] ?? 'Assets';
          assetName = args['assetName'];
          barcode = args['barcode'];
        } else if (settings.arguments is AssetLocal) {
          asset = settings.arguments as AssetLocal;
          category = asset.category;
          barcode = asset.barcode;
        }
        return _buildPageRoute(settings: settings, 
          builder: (_) => AddAssetScreen(
            category: category,
            assetName: assetName,
            barcode: barcode,
            asset: asset,
          ),
        );

      case AppRoutes.vehiclesList:
        return _buildPageRoute(settings: settings, 
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
        return _buildPageRoute(settings: settings, 
          builder: (context) => const MachineryListScreen(),
        );

      case AppRoutes.computerHardwareList:
        return _buildPageRoute(settings: settings, 
          builder: (_) => const ComputerHardwareListScreen(),
        );

      case AppRoutes.computerSoftwareList:
        return _buildPageRoute(settings: settings, 
          builder: (_) => const ComputerSoftwareListScreen(),
        );

      case AppRoutes.furnitureList:
        return _buildPageRoute(settings: settings, builder: (_) => const FurnitureListScreen());

      case AppRoutes.fixedAssetsList:
        return _buildPageRoute(settings: settings, builder: (_) => const FixedAssetsListScreen());

      case AppRoutes.warehouses:
        return _buildPageRoute(settings: settings, builder: (_) => const WarehousesScreen());
      case AppRoutes.contractsList:
        return _buildPageRoute(settings: settings, builder: (_) => const ContractsListScreen());

      case AppRoutes.contractDetail:
        final args = settings.arguments;
        String cName = 'Contract';
        if (args is String) {
          cName = args;
        } else if (args is Map<String, dynamic>) {
          cName = args['name'] ?? args['contractName'] ?? 'Contract';
        }
        return _buildPageRoute(settings: settings, 
          builder: (_) => ContractDetailScreen(contractName: cName),
        );

      case AppRoutes.addContract:
        return _buildPageRoute(settings: settings, builder: (_) => const AddContractScreen());

      // ── Chat ─────────────────────────────────────────────────────────────
      case AppRoutes.chatList:
        return _buildPageRoute(settings: settings, 
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
        return _buildPageRoute(settings: settings, 
          builder: (context) => ChatDetailScreen(
            chatId: chat?.id ?? '1',
            contactName: chat?.name ?? 'Chat',
          ),
        );

      case AppRoutes.forwardMessage:
        final message = settings.arguments as Map<String, dynamic>;
        return _buildPageRoute(settings: settings, 
          builder: (context) => ForwardMessageScreen(message: message),
        );

      // ── Analytics ────────────────────────────────────────────────────────
      case AppRoutes.analytics:
        return _buildPageRoute(settings: settings, builder: (_) => const AnalyticsScreen());

      // ── Reports ──────────────────────────────────────────────────────────
      case AppRoutes.reports:
        return _buildPageRoute(settings: settings, builder: (_) => const ReportsScreen());

      case AppRoutes.reportDetail:
        return _buildPageRoute(settings: settings, 
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
        return _buildPageRoute(settings: settings, builder: (_) => const NotificationsScreen());

      // ── Schedule ────────────────────────────────────────────────────────
      case AppRoutes.schedule:
        return _buildPageRoute(settings: settings, builder: (_) => const ScheduleScreen());
      case AppRoutes.profile:
        return _buildPageRoute(settings: settings, builder: (_) => const ProfileScreen());

      // ── QR Scan ──────────────────────────────────────────────────────────
      case AppRoutes.qrScan:
        return _buildPageRoute(settings: settings, builder: (_) => const QrScanScreen());

      // ── Maintenance ────────────────────────────────────────────────────────
      case AppRoutes.maintenance:
        return _buildPageRoute(settings: settings, builder: (_) => const MaintenanceScreen());

      case AppRoutes.transactions:
        return _buildPageRoute(settings: settings, 
          builder: (_) => const TransactionsListScreen(),
        );

      // ── Settings & Legal ─────────────────────────────────────────────────────────
      case AppRoutes.settings:
        return _buildPageRoute(settings: settings, builder: (_) => const SettingsScreen());
      case AppRoutes.aboutApp:
        return _buildPageRoute(settings: settings, builder: (_) => const AboutAppScreen());
      case AppRoutes.assetsSettings:
        return _buildPageRoute(settings: settings, builder: (_) => const AssetsSettingsScreen());
      case AppRoutes.complianceSettings:
        return _buildPageRoute(settings: settings, 
          builder: (_) => const ComplianceSettingsScreen(),
        );
      case AppRoutes.auditLogs:
        return _buildPageRoute(settings: settings, builder: (_) => const AuditLogScreen());
      case AppRoutes.termsConditions:
        return _buildPageRoute(settings: settings, builder: (_) => const TermsConditionsScreen());
      case AppRoutes.dpa:
        return _buildPageRoute(settings: settings, builder: (_) => const DpaScreen());
      case AppRoutes.privacyPolicy:
        return _buildPageRoute(settings: settings, builder: (_) => const PrivacyPolicyScreen());
      case AppRoutes.backupSync:
        return _buildPageRoute(settings: settings, builder: (_) => const BackupSyncScreen());

      // ── Support ───────────────────────────────────────────────────────────
      case AppRoutes.supportDashboard:
        return _buildPageRoute(settings: settings, 
          builder: (_) => const SupportDashboardScreen(),
        );
      case AppRoutes.createTicket:
        return _buildPageRoute(settings: settings, builder: (_) => const CreateTicketScreen());
      case AppRoutes.ticketDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildPageRoute(settings: settings, 
          builder: (_) => TicketDetailScreen(ticketMap: args),
        );
      case AppRoutes.ticketHistory:
        return _buildPageRoute(settings: settings, builder: (_) => const TicketHistoryScreen());
      case AppRoutes.slaPolicy:
        return _buildPageRoute(settings: settings, builder: (_) => const SlaPolicyScreen());
      case AppRoutes.knowledgeBase:
        return _buildPageRoute(settings: settings, builder: (_) => const KnowledgeBaseScreen());

      // ── Files ─────────────────────────────────────────────────────────────
      case AppRoutes.files:
        return _buildPageRoute(settings: settings, builder: (_) => const FilesScreen());

      case AppRoutes.userManagement:
        return _buildPageRoute(settings: settings, builder: (_) => const UserManagementScreen());

      // ── Location (legacy) ────────────────────────────────────────────────
      case AppRoutes.locationSetup:
        return _buildPageRoute(settings: settings, 
          builder: (context) => LocationSetupScreen(
            onSaveAndContinue: () =>
                Navigator.of(context).pushNamed(AppRoutes.dashboard),
          ),
        );

      case AppRoutes.locationConfirm:
        return _buildPageRoute(settings: settings, 
          builder: (context) => const LocationSetupScreen(),
        );

      case AppRoutes.manualSearch:
        final query = settings.arguments as String?;
        return _buildPageRoute(settings: settings, 
          builder: (_) => ManualSearchScreen(initialQuery: query),
        );

      case AppRoutes.eReceipt:
        final data = settings.arguments as ReceiptData? ?? ReceiptData.mock();
        return _buildPageRoute(settings: settings, builder: (_) => EReceiptScreen(data: data));

      case AppRoutes.realTimeTracking:
        final args = settings.arguments;
        if (args is! AssetLocal) {
          return _buildPageRoute(settings: settings, 
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid Asset for Tracking')),
            ),
          );
        }
        return _buildPageRoute(settings: settings, 
          builder: (_) => RealTimeTrackingScreen(asset: args),
        );

      case AppRoutes.locationPicker:
        return _buildPageRoute(settings: settings, builder: (_) => const LocationPickerScreen());

      case AppRoutes.approvalDashboard:
        return _buildPageRoute(settings: settings, builder: (_) => const ApprovalDashboardScreen());

      default:
        return _buildPageRoute(settings: settings, 
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }

  static Route<dynamic> _buildPageRoute({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) {
    const specialRoutes = [
      AppRoutes.assetDetail,
      AppRoutes.intangibleAssetDetail,
      AppRoutes.vehicleDetail,
      AppRoutes.machineryDetail,
      AppRoutes.computerHardwareDetail,
      AppRoutes.computerSoftwareDetail,
      AppRoutes.furnitureDetail,
      AppRoutes.fixedAssetDetail,
      AppRoutes.contractDetail,
      AppRoutes.ticketDetail,
      AppRoutes.reportDetail,
    ];

    final isSpecial = specialRoutes.contains(settings.name);

    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

        if (isSpecial) {
          return FadeTransition(
            opacity: curve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
              child: child,
            ),
          );
        } else {
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.04),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        }
      },
    );
  }
}
