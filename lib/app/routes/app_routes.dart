class AppRoutes {
  const AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String verifyEmail = '/auth/verify-email';
  static const String setPassword = '/auth/set-password';
  static const String accountDetails = '/auth/account-details';
  static const String registrationComplete = '/auth/registration-complete';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetOtp = '/auth/reset-otp';
  static const String newPassword = '/auth/new-password';

  // ── Main App ──────────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';

  // ── Assets ────────────────────────────────────────────────────────────────
  static const String assets = '/assets';
  static const String intangibleAssets = '/assets/intangible';
  static const String intangibleAssetDetail = '/assets/intangible/detail';
  static const String depreciationSchedule = '/assets/depreciation';
  static const String addAsset = '/assets/add';
  static const String assetDetail = '/assets/detail';
  static const String vehiclesList = '/assets/vehicles';
  static const String vehicleDetail = '/assets/vehicles/detail';
  static const String machineryList = '/assets/machinery';
  static const String machineryDetail = '/assets/machinery/detail';
  static const String computerHardwareList = '/assets/computer-hardware';
  static const String computerHardwareDetail =
      '/assets/computer-hardware/detail';
  static const String computerSoftwareList = '/assets/computer-software';
  static const String computerSoftwareDetail =
      '/assets/computer-software/detail';
  static const String furnitureList = '/assets/furniture';
  static const String furnitureDetail = '/assets/furniture/detail';
  static const String fixedAssetsList = '/assets/fixed-assets';
  static const String fixedAssetDetail = '/assets/fixed-assets/detail';
  static const String warehouses = '/assets/warehouses';

  // ── Chat ─────────────────────────────────────────────────────────────────
  static const String chatList = '/chat';
  static const String chatDetail = '/chat/detail';

  // ── Analytics ─────────────────────────────────────────────────────────────
  static const String analytics = '/analytics';

  // ── Contracts ─────────────────────────────────────────────────────────────
  static const String contractsList = '/contracts';
  static const String contractDetail = '/contracts/detail';
  static const String addContract = '/contracts/add';

  // ── Reports ───────────────────────────────────────────────────────────────
  static const String reports = '/reports';
  static const String reportDetail = '/reports/detail';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/notifications';

  // ── Schedule ──────────────────────────────────────────────────────────────
  static const String schedule = '/schedule';
  static const String profile = '/profile';

  // ── QR Scan ───────────────────────────────────────────────────────────────
  static const String qrScan = '/qr-scan';
  static const String eReceipt = '/ereceipt';

  // ── Maintenance ───────────────────────────────────────────────────────────
  static const String maintenance = '/maintenance';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settings = '/settings';
  static const String aboutApp = '/settings/about';
  static const String assetsSettings = '/settings/assets';
  static const String complianceSettings = '/settings/compliance';
  static const String termsConditions = '/settings/compliance/terms';
  static const String privacyPolicy = '/settings/compliance/privacy';
  static const String dpa = '/settings/compliance/dpa';
  static const String auditLogs = '/settings/compliance/audit';
  static const String backupSync = '/settings/backup';
  static const String userManagement = '/settings/users';

  // ── Support & Help ────────────────────────────────────────────────────────
  static const String supportDashboard = '/support';
  static const String createTicket = '/support/create';
  static const String ticketDetail = '/support/detail';
  static const String ticketHistory = '/support/history';
  static const String slaPolicy = '/support/sla';
  static const String knowledgeBase = '/support/kb';

  // ── Files ─────────────────────────────────────────────────────────────────
  static const String files = '/files';

  // ── Location (legacy) ─────────────────────────────────────────────────────
  static const String locationSetup = '/location/setup';
  static const String locationConfirm = '/location/confirm';
  // ── Manual Search ────────────────────────────────────────────────────────
  static const String manualSearch = '/manual-search';

  // ── Transactions ────────────────────────────────────────────────────────
  static const String transactions = '/transactions';

  // ── Location ────────────────────────────────────────────────────────────
  static const String realTimeTracking = '/location/tracking';
  static const String locationPicker = '/location/picker';
}
