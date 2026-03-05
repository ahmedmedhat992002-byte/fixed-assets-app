import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WorldAssets'**
  String get appTitle;

  /// No description provided for @navAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get navAssets;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get navScanQr;

  /// No description provided for @navMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get navMaintenance;

  /// No description provided for @navFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get navFiles;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get navContactSupport;

  /// No description provided for @navWorkplace.
  ///
  /// In en, this message translates to:
  /// **'Workplace'**
  String get navWorkplace;

  /// No description provided for @navGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get navGeneral;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @sectionIntangibleAssets.
  ///
  /// In en, this message translates to:
  /// **'Intangible assets'**
  String get sectionIntangibleAssets;

  /// No description provided for @sectionMachinery.
  ///
  /// In en, this message translates to:
  /// **'Machinery'**
  String get sectionMachinery;

  /// No description provided for @sectionVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get sectionVehicles;

  /// No description provided for @sectionComputerHardware.
  ///
  /// In en, this message translates to:
  /// **'Computer Hardware'**
  String get sectionComputerHardware;

  /// No description provided for @sectionComputerSoftware.
  ///
  /// In en, this message translates to:
  /// **'Computer Software'**
  String get sectionComputerSoftware;

  /// No description provided for @sectionFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get sectionFurniture;

  /// No description provided for @sectionFixedAssets.
  ///
  /// In en, this message translates to:
  /// **'Fixed assets'**
  String get sectionFixedAssets;

  /// No description provided for @sectionContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get sectionContracts;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardOverview;

  /// No description provided for @dashboardRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get dashboardRecentlyAdded;

  /// No description provided for @dashboardLatestTransactions.
  ///
  /// In en, this message translates to:
  /// **'Latest Transactions'**
  String get dashboardLatestTransactions;

  /// No description provided for @dashboardNoRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions.'**
  String get dashboardNoRecentTransactions;

  /// No description provided for @dashboardTotalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get dashboardTotalAssets;

  /// No description provided for @dashboardTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get dashboardTotalValue;

  /// No description provided for @dashboardAssetsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Assets by Category'**
  String get dashboardAssetsByCategory;

  /// No description provided for @dashboardAssetsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Assets by Status'**
  String get dashboardAssetsByStatus;

  /// No description provided for @dashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get dashboardViewAll;

  /// No description provided for @dashboardActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashboardActive;

  /// No description provided for @dashboardInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get dashboardInactive;

  /// No description provided for @dashboardUnderMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Under Maintenance'**
  String get dashboardUnderMaintenance;

  /// No description provided for @dashboardDepreciated.
  ///
  /// In en, this message translates to:
  /// **'Depreciated'**
  String get dashboardDepreciated;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analyticsAnalysis;

  /// No description provided for @analyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get analyticsDashboard;

  /// No description provided for @analyticsAssetTrends.
  ///
  /// In en, this message translates to:
  /// **'Asset Trends'**
  String get analyticsAssetTrends;

  /// No description provided for @analyticsSixMonthsOverview.
  ///
  /// In en, this message translates to:
  /// **'6 months overview'**
  String get analyticsSixMonthsOverview;

  /// No description provided for @analyticsByCategory.
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get analyticsByCategory;

  /// No description provided for @analyticsByStatus.
  ///
  /// In en, this message translates to:
  /// **'By Status'**
  String get analyticsByStatus;

  /// No description provided for @analyticsMaintenanceCosts.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Costs'**
  String get analyticsMaintenanceCosts;

  /// No description provided for @analyticsValueOnRegistration.
  ///
  /// In en, this message translates to:
  /// **'Value on registration'**
  String get analyticsValueOnRegistration;

  /// No description provided for @analyticsCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current value'**
  String get analyticsCurrentValue;

  /// No description provided for @analyticsProjectedIncrease.
  ///
  /// In en, this message translates to:
  /// **'Projected increase'**
  String get analyticsProjectedIncrease;

  /// No description provided for @analyticsEmergency.
  ///
  /// In en, this message translates to:
  /// **'emergency'**
  String get analyticsEmergency;

  /// No description provided for @analyticsScheduled.
  ///
  /// In en, this message translates to:
  /// **'scheduled'**
  String get analyticsScheduled;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get reportsThisWeek;

  /// No description provided for @reportsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get reportsThisMonth;

  /// No description provided for @reportsThisQuarter.
  ///
  /// In en, this message translates to:
  /// **'This Quarter'**
  String get reportsThisQuarter;

  /// No description provided for @reportsThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get reportsThisYear;

  /// No description provided for @reportsAssetsReport.
  ///
  /// In en, this message translates to:
  /// **'Assets Report'**
  String get reportsAssetsReport;

  /// No description provided for @reportsAssetsReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete asset inventory and valuation'**
  String get reportsAssetsReportSubtitle;

  /// No description provided for @reportsMaintenanceReport.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Report'**
  String get reportsMaintenanceReport;

  /// No description provided for @reportsMaintenanceReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Service history and schedules.'**
  String get reportsMaintenanceReportSubtitle;

  /// No description provided for @reportsFinancialReport.
  ///
  /// In en, this message translates to:
  /// **'Financial Report'**
  String get reportsFinancialReport;

  /// No description provided for @reportsFinancialReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Costs, depreciation, and ROI'**
  String get reportsFinancialReportSubtitle;

  /// No description provided for @reportsTotalMonth.
  ///
  /// In en, this message translates to:
  /// **'Total month'**
  String get reportsTotalMonth;

  /// No description provided for @reportsElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get reportsElectronics;

  /// No description provided for @reportsFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get reportsFurniture;

  /// No description provided for @reportsVehiclesTag.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get reportsVehiclesTag;

  /// No description provided for @reportsEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get reportsEquipment;

  /// No description provided for @reportsPreventive.
  ///
  /// In en, this message translates to:
  /// **'Preventive'**
  String get reportsPreventive;

  /// No description provided for @reportsCorrective.
  ///
  /// In en, this message translates to:
  /// **'Corrective'**
  String get reportsCorrective;

  /// No description provided for @reportsEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get reportsEmergency;

  /// No description provided for @reportsScheduledTag.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get reportsScheduledTag;

  /// No description provided for @reportsPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get reportsPurchase;

  /// No description provided for @reportsDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Depreciation'**
  String get reportsDepreciation;

  /// No description provided for @reportsDisposal.
  ///
  /// In en, this message translates to:
  /// **'Disposal'**
  String get reportsDisposal;

  /// No description provided for @reportsPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get reportsPdf;

  /// No description provided for @reportsExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get reportsExcel;

  /// No description provided for @reportsCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get reportsCsv;

  /// No description provided for @reportsRecentReports.
  ///
  /// In en, this message translates to:
  /// **'Recent Reports'**
  String get reportsRecentReports;

  /// No description provided for @reportsMonthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get reportsMonthlySummary;

  /// No description provided for @reportsGeneratedToday.
  ///
  /// In en, this message translates to:
  /// **'Generated today'**
  String get reportsGeneratedToday;

  /// No description provided for @reportsAssetDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Asset Depreciation'**
  String get reportsAssetDepreciation;

  /// No description provided for @reportsGenerated2DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Generated 2 days ago'**
  String get reportsGenerated2DaysAgo;

  /// No description provided for @reportsMaintenanceSchedule.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Schedule'**
  String get reportsMaintenanceSchedule;

  /// No description provided for @reportsGenerated3DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Generated 3 days ago'**
  String get reportsGenerated3DaysAgo;

  /// No description provided for @reportsCostAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Cost Analysis'**
  String get reportsCostAnalysis;

  /// No description provided for @reportsGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get reportsGenerating;

  /// No description provided for @reportsReportSummary.
  ///
  /// In en, this message translates to:
  /// **'Report Summary'**
  String get reportsReportSummary;

  /// No description provided for @reportsTotalReports.
  ///
  /// In en, this message translates to:
  /// **'Total Reports'**
  String get reportsTotalReports;

  /// No description provided for @reportsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get reportsScheduled;

  /// No description provided for @reportsAutomated.
  ///
  /// In en, this message translates to:
  /// **'Automated'**
  String get reportsAutomated;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get maintenanceUpcoming;

  /// No description provided for @maintenanceInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get maintenanceInProgress;

  /// No description provided for @maintenanceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get maintenanceCompleted;

  /// No description provided for @maintenanceSearch.
  ///
  /// In en, this message translates to:
  /// **'Search maintenance...'**
  String get maintenanceSearch;

  /// No description provided for @maintenanceAddRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get maintenanceAddRecord;

  /// No description provided for @maintenanceDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get maintenanceDue;

  /// No description provided for @maintenancePriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get maintenancePriority;

  /// No description provided for @maintenanceHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get maintenanceHigh;

  /// No description provided for @maintenanceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get maintenanceMedium;

  /// No description provided for @maintenanceLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get maintenanceLow;

  /// No description provided for @maintenanceTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get maintenanceTechnician;

  /// No description provided for @maintenanceCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get maintenanceCost;

  /// No description provided for @filesTitle.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTitle;

  /// No description provided for @filesUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get filesUpload;

  /// No description provided for @filesFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get filesFolders;

  /// No description provided for @filesRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get filesRecentFiles;

  /// No description provided for @filesFileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get filesFileName;

  /// No description provided for @filesFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get filesFileSize;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get settingsBusiness;

  /// No description provided for @settingsGeneralTab.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneralTab;

  /// No description provided for @settingsFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get settingsFirstName;

  /// No description provided for @settingsLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get settingsLastName;

  /// No description provided for @settingsCurrentPosition.
  ///
  /// In en, this message translates to:
  /// **'Current position'**
  String get settingsCurrentPosition;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get settingsEmail;

  /// No description provided for @settingsPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get settingsPhoneNumber;

  /// No description provided for @settingsAddProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add profile photo +'**
  String get settingsAddProfilePhoto;

  /// No description provided for @settingsBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get settingsBusinessName;

  /// No description provided for @settingsIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get settingsIndustry;

  /// No description provided for @settingsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingsLocation;

  /// No description provided for @settingsBusinessEmail.
  ///
  /// In en, this message translates to:
  /// **'Business e-mail'**
  String get settingsBusinessEmail;

  /// No description provided for @settingsBusinessNumber.
  ///
  /// In en, this message translates to:
  /// **'Business number'**
  String get settingsBusinessNumber;

  /// No description provided for @settingsValuation.
  ///
  /// In en, this message translates to:
  /// **'Valuation'**
  String get settingsValuation;

  /// No description provided for @settingsEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get settingsEmployees;

  /// No description provided for @settingsCompanyLogo.
  ///
  /// In en, this message translates to:
  /// **'Company logo +'**
  String get settingsCompanyLogo;

  /// No description provided for @settingsNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get settingsNotification;

  /// No description provided for @settingsAppPreferences.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get settingsAppPreferences;

  /// No description provided for @settingsAssetsSettings.
  ///
  /// In en, this message translates to:
  /// **'Assets Settings'**
  String get settingsAssetsSettings;

  /// No description provided for @settingsUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get settingsUserManagement;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsSupportHelp.
  ///
  /// In en, this message translates to:
  /// **'Support & Help'**
  String get settingsSupportHelp;

  /// No description provided for @settingsBackupSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & Sync'**
  String get settingsBackupSync;

  /// No description provided for @settingsAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get settingsAboutApp;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get settingsComingSoon;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifAll;

  /// No description provided for @notifUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notifUnread;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifMarkAllRead;

  /// No description provided for @notifToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notifToday;

  /// No description provided for @notifThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get notifThisWeek;

  /// No description provided for @notifEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notifEarlier;

  /// No description provided for @notifSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notifSettingsTitle;

  /// No description provided for @notifSettingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General notification'**
  String get notifSettingsGeneral;

  /// No description provided for @notifSettingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get notifSettingsSound;

  /// No description provided for @notifSettingsVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get notifSettingsVibrate;

  /// No description provided for @notifSettingsSpecialOffers.
  ///
  /// In en, this message translates to:
  /// **'Special offers'**
  String get notifSettingsSpecialOffers;

  /// No description provided for @notifSettingsPromo.
  ///
  /// In en, this message translates to:
  /// **'Promo & discount'**
  String get notifSettingsPromo;

  /// No description provided for @notifSettingsAppUpdates.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get notifSettingsAppUpdates;

  /// No description provided for @notifSettingsNewService.
  ///
  /// In en, this message translates to:
  /// **'New service available'**
  String get notifSettingsNewService;

  /// No description provided for @notifSettingsNewTips.
  ///
  /// In en, this message translates to:
  /// **'New tips available'**
  String get notifSettingsNewTips;

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated successfully'**
  String get settingsUpdated;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @securityRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get securityRememberMe;

  /// No description provided for @securityFaceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get securityFaceId;

  /// No description provided for @securityBiometricId.
  ///
  /// In en, this message translates to:
  /// **'Biometric ID'**
  String get securityBiometricId;

  /// No description provided for @securityGoogleAuth.
  ///
  /// In en, this message translates to:
  /// **'Google authenticator'**
  String get securityGoogleAuth;

  /// No description provided for @securityChangePIN.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get securityChangePIN;

  /// No description provided for @securityChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get securityChangePassword;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglishUS.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get languageEnglishUS;

  /// No description provided for @languageEnglishUK.
  ///
  /// In en, this message translates to:
  /// **'English (UK)'**
  String get languageEnglishUK;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageItalien.
  ///
  /// In en, this message translates to:
  /// **'Italien'**
  String get languageItalien;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get languageDutch;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Mandarin Chinese'**
  String get languageChinese;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @addAssetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get addAssetTitle;

  /// No description provided for @addAssetDetails.
  ///
  /// In en, this message translates to:
  /// **'Asset details'**
  String get addAssetDetails;

  /// No description provided for @addAssetStakeholder.
  ///
  /// In en, this message translates to:
  /// **'Stakeholder'**
  String get addAssetStakeholder;

  /// No description provided for @addAssetMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get addAssetMore;

  /// No description provided for @addAssetName.
  ///
  /// In en, this message translates to:
  /// **'Asset Name'**
  String get addAssetName;

  /// No description provided for @addAssetCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get addAssetCategory;

  /// No description provided for @addAssetType.
  ///
  /// In en, this message translates to:
  /// **'Asset Type'**
  String get addAssetType;

  /// No description provided for @addAssetLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get addAssetLocation;

  /// No description provided for @addAssetPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get addAssetPurchaseDate;

  /// No description provided for @addAssetPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get addAssetPurchasePrice;

  /// No description provided for @addAssetUsefulLife.
  ///
  /// In en, this message translates to:
  /// **'Useful Life'**
  String get addAssetUsefulLife;

  /// No description provided for @addAssetSalvageValue.
  ///
  /// In en, this message translates to:
  /// **'Salvage Value'**
  String get addAssetSalvageValue;

  /// No description provided for @addAssetDepreciationMethod.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Method'**
  String get addAssetDepreciationMethod;

  /// No description provided for @addAssetDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get addAssetDescription;

  /// No description provided for @addAssetSave.
  ///
  /// In en, this message translates to:
  /// **'Save Asset'**
  String get addAssetSave;

  /// No description provided for @addAssetPaymentPlan.
  ///
  /// In en, this message translates to:
  /// **'Payment plan'**
  String get addAssetPaymentPlan;

  /// No description provided for @addAssetUploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload documents'**
  String get addAssetUploadDocuments;

  /// No description provided for @addAssetDragDrop.
  ///
  /// In en, this message translates to:
  /// **'Drag & drop files or click to upload'**
  String get addAssetDragDrop;

  /// No description provided for @addAssetSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get addAssetSelectFile;

  /// No description provided for @addAssetMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get addAssetMonthly;

  /// No description provided for @addAssetQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get addAssetQuarterly;

  /// No description provided for @addAssetAnnually.
  ///
  /// In en, this message translates to:
  /// **'Annually'**
  String get addAssetAnnually;

  /// No description provided for @vehicleDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get vehicleDetailTitle;

  /// No description provided for @vehicleDetailAssetDetails.
  ///
  /// In en, this message translates to:
  /// **'Asset details'**
  String get vehicleDetailAssetDetails;

  /// No description provided for @vehicleDetailStakeholderDetails.
  ///
  /// In en, this message translates to:
  /// **'Stakeholder details'**
  String get vehicleDetailStakeholderDetails;

  /// No description provided for @vehicleDetailDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get vehicleDetailDocuments;

  /// No description provided for @vehicleDetailAssetName.
  ///
  /// In en, this message translates to:
  /// **'Asset Name'**
  String get vehicleDetailAssetName;

  /// No description provided for @vehicleDetailAssetId.
  ///
  /// In en, this message translates to:
  /// **'Asset ID'**
  String get vehicleDetailAssetId;

  /// No description provided for @vehicleDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get vehicleDetailStatus;

  /// No description provided for @vehicleDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get vehicleDetailCategory;

  /// No description provided for @vehicleDetailDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get vehicleDetailDepartment;

  /// No description provided for @vehicleDetailPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get vehicleDetailPurchaseDate;

  /// No description provided for @vehicleDetailPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get vehicleDetailPurchasePrice;

  /// No description provided for @vehicleDetailCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current Value'**
  String get vehicleDetailCurrentValue;

  /// No description provided for @vehicleDetailDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Depreciation'**
  String get vehicleDetailDepreciation;

  /// No description provided for @vehicleDetailLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get vehicleDetailLocation;

  /// No description provided for @machineryListTitle.
  ///
  /// In en, this message translates to:
  /// **'Machinery'**
  String get machineryListTitle;

  /// No description provided for @machineryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Machinery Details'**
  String get machineryDetailTitle;

  /// No description provided for @vehiclesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehiclesListTitle;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get scheduleAddEvent;

  /// No description provided for @scheduleNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events scheduled'**
  String get scheduleNoEvents;

  /// No description provided for @qrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScanTitle;

  /// No description provided for @qrScanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Align the QR code within the frame'**
  String get qrScanInstruction;

  /// No description provided for @qrScanPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get qrScanPermission;

  /// No description provided for @qrScanGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get qrScanGrant;

  /// No description provided for @ereceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'E-Receipt'**
  String get ereceiptTitle;

  /// No description provided for @ereceiptShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get ereceiptShare;

  /// No description provided for @ereceiptDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get ereceiptDownload;

  /// No description provided for @ereceiptPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get ereceiptPrint;

  /// No description provided for @depreciationTitle.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Schedule'**
  String get depreciationTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupTitle;

  /// No description provided for @signupName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signupName;

  /// No description provided for @signupEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmail;

  /// No description provided for @signupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPassword;

  /// No description provided for @signupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmPassword;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupButton;

  /// No description provided for @signupHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signupHaveAccount;

  /// No description provided for @signupLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get signupLogin;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your password'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get forgotPasswordEmail;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotPasswordButton;

  /// No description provided for @forgotPasswordBack.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get forgotPasswordBack;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get errorUnexpected;

  /// No description provided for @errorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get errorTryAgain;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get buttonConfirm;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @buttonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get buttonClose;

  /// No description provided for @buttonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get buttonNext;

  /// No description provided for @buttonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get buttonBack;

  /// No description provided for @buttonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get buttonSearch;

  /// No description provided for @buttonFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get buttonFilter;

  /// No description provided for @buttonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get buttonAdd;

  /// No description provided for @buttonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get buttonEdit;

  /// No description provided for @buttonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buttonDelete;

  /// No description provided for @buttonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get buttonShare;

  /// No description provided for @buttonDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get buttonDownload;

  /// No description provided for @buttonPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get buttonPrint;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'World Assets App is a comprehensive asset management platform designed to track, manage, and analyze physical and digital assets efficiently.'**
  String get aboutAppDescription;

  /// No description provided for @aboutAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutAppVersion;

  /// No description provided for @aboutAppBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get aboutAppBuild;

  /// No description provided for @aboutAppCompany.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get aboutAppCompany;

  /// No description provided for @aboutAppSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support Email'**
  String get aboutAppSupportEmail;

  /// No description provided for @aboutAppWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutAppWebsite;

  /// No description provided for @aboutAppCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 WorldAssets. All rights reserved.'**
  String get aboutAppCopyright;

  /// No description provided for @aboutAppPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutAppPrivacyPolicy;

  /// No description provided for @aboutAppTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get aboutAppTermsAndConditions;

  /// No description provided for @assetsSettingsGeneralConfig.
  ///
  /// In en, this message translates to:
  /// **'General Asset Configuration'**
  String get assetsSettingsGeneralConfig;

  /// No description provided for @assetsSettingsDefaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get assetsSettingsDefaultCurrency;

  /// No description provided for @assetsSettingsDefaultDepreciationMethod.
  ///
  /// In en, this message translates to:
  /// **'Default Depreciation Method'**
  String get assetsSettingsDefaultDepreciationMethod;

  /// No description provided for @assetsSettingsDefaultAssetStatus.
  ///
  /// In en, this message translates to:
  /// **'Default Asset Status'**
  String get assetsSettingsDefaultAssetStatus;

  /// No description provided for @assetsSettingsFiscalYearStart.
  ///
  /// In en, this message translates to:
  /// **'Fiscal Year Start'**
  String get assetsSettingsFiscalYearStart;

  /// No description provided for @assetsSettingsCategoriesMgmt.
  ///
  /// In en, this message translates to:
  /// **'Asset Categories Management'**
  String get assetsSettingsCategoriesMgmt;

  /// No description provided for @assetsSettingsAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get assetsSettingsAddCategory;

  /// No description provided for @assetsSettingsEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get assetsSettingsEditCategory;

  /// No description provided for @assetsSettingsDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get assetsSettingsDeleteCategory;

  /// No description provided for @assetsSettingsDeleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get assetsSettingsDeleteCategoryConfirm;

  /// No description provided for @assetsSettingsCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get assetsSettingsCategoryName;

  /// No description provided for @assetsSettingsNotificationsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Alerts'**
  String get assetsSettingsNotificationsAlerts;

  /// No description provided for @assetsSettingsEnableMaintenanceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable Maintenance Alerts'**
  String get assetsSettingsEnableMaintenanceAlerts;

  /// No description provided for @assetsSettingsEnableDepreciationAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable Depreciation Alerts'**
  String get assetsSettingsEnableDepreciationAlerts;

  /// No description provided for @assetsSettingsEnableExpiryAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable Expiry Alerts'**
  String get assetsSettingsEnableExpiryAlerts;

  /// No description provided for @assetsSettingsDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get assetsSettingsDataManagement;

  /// No description provided for @assetsSettingsExportAssets.
  ///
  /// In en, this message translates to:
  /// **'Export Assets'**
  String get assetsSettingsExportAssets;

  /// No description provided for @assetsSettingsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Assets exported successfully'**
  String get assetsSettingsExportSuccess;

  /// No description provided for @assetsSettingsResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Asset Settings'**
  String get assetsSettingsResetSettings;

  /// No description provided for @assetsSettingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to revert all asset settings to default?'**
  String get assetsSettingsResetConfirm;

  /// No description provided for @assetsSettingsDateError.
  ///
  /// In en, this message translates to:
  /// **'Invalid Date'**
  String get assetsSettingsDateError;

  /// No description provided for @assetsSettingsAdminMode.
  ///
  /// In en, this message translates to:
  /// **'Admin Mode'**
  String get assetsSettingsAdminMode;

  /// No description provided for @assetsSettingsViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View Only'**
  String get assetsSettingsViewOnly;

  /// No description provided for @assetsSettingsAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: You do not have permission to modify these settings.'**
  String get assetsSettingsAccessDenied;

  /// No description provided for @assetsSettingsAssetType.
  ///
  /// In en, this message translates to:
  /// **'Asset Type'**
  String get assetsSettingsAssetType;

  /// No description provided for @assetsSettingsTypePhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get assetsSettingsTypePhysical;

  /// No description provided for @assetsSettingsTypeDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get assetsSettingsTypeDigital;

  /// No description provided for @assetsSettingsTypeFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get assetsSettingsTypeFinancial;

  /// No description provided for @assetsSettingsMaintenanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Required?'**
  String get assetsSettingsMaintenanceRequired;

  /// No description provided for @assetsSettingsCustomFields.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields'**
  String get assetsSettingsCustomFields;

  /// No description provided for @assetsSettingsAddCustomField.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Field'**
  String get assetsSettingsAddCustomField;

  /// No description provided for @assetsSettingsCustomFieldName.
  ///
  /// In en, this message translates to:
  /// **'Field Name'**
  String get assetsSettingsCustomFieldName;

  /// No description provided for @assetsSettingsDepreciationEngine.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Engine'**
  String get assetsSettingsDepreciationEngine;

  /// No description provided for @assetsSettingsUsefulLife.
  ///
  /// In en, this message translates to:
  /// **'Default Useful Life (Years)'**
  String get assetsSettingsUsefulLife;

  /// No description provided for @assetsSettingsResidualValue.
  ///
  /// In en, this message translates to:
  /// **'Residual Value (%)'**
  String get assetsSettingsResidualValue;

  /// No description provided for @assetsSettingsAutoCalculate.
  ///
  /// In en, this message translates to:
  /// **'Auto-calculate Depreciation'**
  String get assetsSettingsAutoCalculate;

  /// No description provided for @assetsSettingsFiscalFinancial.
  ///
  /// In en, this message translates to:
  /// **'Fiscal & Financial Configuration'**
  String get assetsSettingsFiscalFinancial;

  /// No description provided for @assetsSettingsBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get assetsSettingsBaseCurrency;

  /// No description provided for @assetsSettingsTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate (%)'**
  String get assetsSettingsTaxRate;

  /// No description provided for @assetsSettingsCapitalizationThreshold.
  ///
  /// In en, this message translates to:
  /// **'Capitalization Threshold'**
  String get assetsSettingsCapitalizationThreshold;

  /// No description provided for @assetsSettingsMaintenanceReminder.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Reminder (Days before)'**
  String get assetsSettingsMaintenanceReminder;

  /// No description provided for @assetsSettingsExpiryReminder.
  ///
  /// In en, this message translates to:
  /// **'Expiry Reminder (Days before)'**
  String get assetsSettingsExpiryReminder;

  /// No description provided for @assetsSettingsDepreciationSummary.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Summary Monthly Report'**
  String get assetsSettingsDepreciationSummary;

  /// No description provided for @assetsSettingsContractRenewalReminder.
  ///
  /// In en, this message translates to:
  /// **'Contract Renewal Reminder (Days)'**
  String get assetsSettingsContractRenewalReminder;

  /// No description provided for @assetsSettingsDataGovernance.
  ///
  /// In en, this message translates to:
  /// **'Data Governance'**
  String get assetsSettingsDataGovernance;

  /// No description provided for @assetsSettingsImportAssets.
  ///
  /// In en, this message translates to:
  /// **'Import Assets'**
  String get assetsSettingsImportAssets;

  /// No description provided for @assetsSettingsArchiveOldAssets.
  ///
  /// In en, this message translates to:
  /// **'Archive Old Assets'**
  String get assetsSettingsArchiveOldAssets;

  /// No description provided for @assetsSettingsArchiveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Action successful (Simulation)'**
  String get assetsSettingsArchiveSuccess;

  /// No description provided for @depreciationStraightLine.
  ///
  /// In en, this message translates to:
  /// **'Straight Line'**
  String get depreciationStraightLine;

  /// No description provided for @depreciationDecliningBalance.
  ///
  /// In en, this message translates to:
  /// **'Declining Balance'**
  String get depreciationDecliningBalance;

  /// No description provided for @depreciationUnitsOfProduction.
  ///
  /// In en, this message translates to:
  /// **'Units of Production'**
  String get depreciationUnitsOfProduction;

  /// No description provided for @complianceSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Compliance & Legal'**
  String get complianceSettingsTitle;

  /// No description provided for @complianceSettingsLegalDocs.
  ///
  /// In en, this message translates to:
  /// **'Legal Documents'**
  String get complianceSettingsLegalDocs;

  /// No description provided for @complianceSettingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get complianceSettingsPrivacyPolicy;

  /// No description provided for @complianceSettingsTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get complianceSettingsTermsConditions;

  /// No description provided for @complianceSettingsDPA.
  ///
  /// In en, this message translates to:
  /// **'Data Processing Agreement'**
  String get complianceSettingsDPA;

  /// No description provided for @complianceSettingsConsentMgmt.
  ///
  /// In en, this message translates to:
  /// **'Consent Management'**
  String get complianceSettingsConsentMgmt;

  /// No description provided for @complianceSettingsConsentPrivacy.
  ///
  /// In en, this message translates to:
  /// **'I consent to the Privacy Policy'**
  String get complianceSettingsConsentPrivacy;

  /// No description provided for @complianceSettingsConsentTerms.
  ///
  /// In en, this message translates to:
  /// **'I consent to the Terms & Conditions'**
  String get complianceSettingsConsentTerms;

  /// No description provided for @complianceSettingsConsentNotifications.
  ///
  /// In en, this message translates to:
  /// **'I consent to receive Notifications'**
  String get complianceSettingsConsentNotifications;

  /// No description provided for @complianceSettingsConsentWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Consent Withdrawn'**
  String get complianceSettingsConsentWithdrawn;

  /// No description provided for @complianceSettingsConsentGranted.
  ///
  /// In en, this message translates to:
  /// **'Consent Granted'**
  String get complianceSettingsConsentGranted;

  /// No description provided for @complianceSettingsAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get complianceSettingsAuditLogs;

  /// No description provided for @complianceSettingsDataSubjectRights.
  ///
  /// In en, this message translates to:
  /// **'Data Subject Rights'**
  String get complianceSettingsDataSubjectRights;

  /// No description provided for @complianceSettingsRequestDataExport.
  ///
  /// In en, this message translates to:
  /// **'Request Data Export'**
  String get complianceSettingsRequestDataExport;

  /// No description provided for @complianceSettingsRequestAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Request Account Deletion'**
  String get complianceSettingsRequestAccountDeletion;

  /// No description provided for @complianceSettingsExportSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulating secure JSON data export...'**
  String get complianceSettingsExportSimulate;

  /// No description provided for @complianceSettingsDeletionSimulate.
  ///
  /// In en, this message translates to:
  /// **'Account deletion request submitted to Admin.'**
  String get complianceSettingsDeletionSimulate;

  /// No description provided for @auditLogAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditLogAction;

  /// No description provided for @auditLogTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get auditLogTimestamp;

  /// No description provided for @auditLogUserRole.
  ///
  /// In en, this message translates to:
  /// **'User Role'**
  String get auditLogUserRole;

  /// No description provided for @auditLogEntity.
  ///
  /// In en, this message translates to:
  /// **'Entity Affected'**
  String get auditLogEntity;

  /// No description provided for @auditLogLoginAction.
  ///
  /// In en, this message translates to:
  /// **'User Login'**
  String get auditLogLoginAction;

  /// No description provided for @auditLogConfigAction.
  ///
  /// In en, this message translates to:
  /// **'Settings Modified'**
  String get auditLogConfigAction;

  /// No description provided for @auditLogAssetDeletion.
  ///
  /// In en, this message translates to:
  /// **'Asset Permanently Deleted'**
  String get auditLogAssetDeletion;

  /// No description provided for @legalTermsDefinitions.
  ///
  /// In en, this message translates to:
  /// **'Definitions'**
  String get legalTermsDefinitions;

  /// No description provided for @legalTermsAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Acceptance of Terms'**
  String get legalTermsAcceptance;

  /// No description provided for @legalTermsUserObligations.
  ///
  /// In en, this message translates to:
  /// **'User Obligations'**
  String get legalTermsUserObligations;

  /// No description provided for @legalTermsAccountResp.
  ///
  /// In en, this message translates to:
  /// **'Account Responsibility'**
  String get legalTermsAccountResp;

  /// No description provided for @legalTermsIP.
  ///
  /// In en, this message translates to:
  /// **'Intellectual Property Rights'**
  String get legalTermsIP;

  /// No description provided for @legalTermsServiceMod.
  ///
  /// In en, this message translates to:
  /// **'Service Availability & Modifications'**
  String get legalTermsServiceMod;

  /// No description provided for @legalTermsLiability.
  ///
  /// In en, this message translates to:
  /// **'Limitation of Liability'**
  String get legalTermsLiability;

  /// No description provided for @legalTermsIndemnification.
  ///
  /// In en, this message translates to:
  /// **'Indemnification Clause'**
  String get legalTermsIndemnification;

  /// No description provided for @legalTermsTermination.
  ///
  /// In en, this message translates to:
  /// **'Termination'**
  String get legalTermsTermination;

  /// No description provided for @legalTermsGovLaw.
  ///
  /// In en, this message translates to:
  /// **'Governing Law & Jurisdiction'**
  String get legalTermsGovLaw;

  /// No description provided for @legalTermsDispute.
  ///
  /// In en, this message translates to:
  /// **'Dispute Resolution'**
  String get legalTermsDispute;

  /// No description provided for @legalTermsAmendments.
  ///
  /// In en, this message translates to:
  /// **'Amendments'**
  String get legalTermsAmendments;

  /// No description provided for @legalDPARoles.
  ///
  /// In en, this message translates to:
  /// **'Roles (Controller / Processor)'**
  String get legalDPARoles;

  /// No description provided for @legalDPAPurpose.
  ///
  /// In en, this message translates to:
  /// **'Nature & Purpose of Processing'**
  String get legalDPAPurpose;

  /// No description provided for @legalDPASubjects.
  ///
  /// In en, this message translates to:
  /// **'Categories of Data Subjects'**
  String get legalDPASubjects;

  /// No description provided for @legalDPADataCat.
  ///
  /// In en, this message translates to:
  /// **'Categories of Personal Data'**
  String get legalDPADataCat;

  /// No description provided for @legalDPATechMeasures.
  ///
  /// In en, this message translates to:
  /// **'Technical & Organizational Measures'**
  String get legalDPATechMeasures;

  /// No description provided for @legalDPASubProcessors.
  ///
  /// In en, this message translates to:
  /// **'Sub-processors'**
  String get legalDPASubProcessors;

  /// No description provided for @legalDPAIntTransfers.
  ///
  /// In en, this message translates to:
  /// **'International Transfers'**
  String get legalDPAIntTransfers;

  /// No description provided for @legalDPAAuditRights.
  ///
  /// In en, this message translates to:
  /// **'Audit Rights'**
  String get legalDPAAuditRights;

  /// No description provided for @legalDPABreach.
  ///
  /// In en, this message translates to:
  /// **'Breach Notification Procedure'**
  String get legalDPABreach;

  /// No description provided for @legalTextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This section outlines the enterprise-grade legal framework concerning the designated topic, establishing legally binding obligations, processing standards, and regulatory compliance requirements in accordance with international law (e.g., GDPR Article 28). Full text to be reviewed by formal counsel.'**
  String get legalTextPlaceholder;

  /// No description provided for @supportDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Support & Help Desk'**
  String get supportDashboardTitle;

  /// No description provided for @supportTicketsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Tickets'**
  String get supportTicketsOpen;

  /// No description provided for @supportTicketsInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get supportTicketsInProgress;

  /// No description provided for @supportTicketsResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get supportTicketsResolved;

  /// No description provided for @supportSLABreach.
  ///
  /// In en, this message translates to:
  /// **'SLA Breaches'**
  String get supportSLABreach;

  /// No description provided for @supportCreateTicket.
  ///
  /// In en, this message translates to:
  /// **'Create New Ticket'**
  String get supportCreateTicket;

  /// No description provided for @supportTicketHistory.
  ///
  /// In en, this message translates to:
  /// **'Ticket History'**
  String get supportTicketHistory;

  /// No description provided for @supportKnowledgeBase.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Base (FAQ)'**
  String get supportKnowledgeBase;

  /// No description provided for @supportSLAPolicy.
  ///
  /// In en, this message translates to:
  /// **'SLA Configuration'**
  String get supportSLAPolicy;

  /// No description provided for @ticketTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Ticket Title (Required)'**
  String get ticketTitleRequired;

  /// No description provided for @ticketCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get ticketCategory;

  /// No description provided for @ticketCategoryTech.
  ///
  /// In en, this message translates to:
  /// **'Technical Issue'**
  String get ticketCategoryTech;

  /// No description provided for @ticketCategoryAsset.
  ///
  /// In en, this message translates to:
  /// **'Asset Error'**
  String get ticketCategoryAsset;

  /// No description provided for @ticketCategoryContract.
  ///
  /// In en, this message translates to:
  /// **'Contract Issue'**
  String get ticketCategoryContract;

  /// No description provided for @ticketCategoryBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get ticketCategoryBilling;

  /// No description provided for @ticketCategorySecurity.
  ///
  /// In en, this message translates to:
  /// **'Security Concern'**
  String get ticketCategorySecurity;

  /// No description provided for @ticketCategoryFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get ticketCategoryFeature;

  /// No description provided for @ticketPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get ticketPriority;

  /// No description provided for @ticketPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get ticketPriorityLow;

  /// No description provided for @ticketPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get ticketPriorityMedium;

  /// No description provided for @ticketPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get ticketPriorityHigh;

  /// No description provided for @ticketPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get ticketPriorityCritical;

  /// No description provided for @ticketDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (Detailed summary)'**
  String get ticketDescription;

  /// No description provided for @ticketRelatedEntity.
  ///
  /// In en, this message translates to:
  /// **'Related Entity (Optional)'**
  String get ticketRelatedEntity;

  /// No description provided for @ticketSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get ticketSubmit;

  /// No description provided for @ticketSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ticket successfully generated'**
  String get ticketSubmitSuccess;

  /// No description provided for @ticketStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ticketStatus;

  /// No description provided for @ticketStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ticketStatusOpen;

  /// No description provided for @ticketStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get ticketStatusInProgress;

  /// No description provided for @ticketStatusAwaitingUser.
  ///
  /// In en, this message translates to:
  /// **'Awaiting User'**
  String get ticketStatusAwaitingUser;

  /// No description provided for @ticketStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get ticketStatusResolved;

  /// No description provided for @ticketStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get ticketStatusClosed;

  /// No description provided for @ticketId.
  ///
  /// In en, this message translates to:
  /// **'Ticket ID'**
  String get ticketId;

  /// No description provided for @ticketCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Creation Date'**
  String get ticketCreatedAt;

  /// No description provided for @ticketLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get ticketLastUpdated;

  /// No description provided for @ticketConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation Thread'**
  String get ticketConversation;

  /// No description provided for @ticketChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get ticketChangeStatus;

  /// No description provided for @ticketCloseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close this ticket?'**
  String get ticketCloseConfirm;

  /// No description provided for @slaPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'SLA Response Thresholds'**
  String get slaPolicyTitle;

  /// No description provided for @slaLowThreshold.
  ///
  /// In en, this message translates to:
  /// **'Low Priority (Hours)'**
  String get slaLowThreshold;

  /// No description provided for @slaMediumThreshold.
  ///
  /// In en, this message translates to:
  /// **'Medium Priority (Hours)'**
  String get slaMediumThreshold;

  /// No description provided for @slaHighThreshold.
  ///
  /// In en, this message translates to:
  /// **'High Priority (Hours)'**
  String get slaHighThreshold;

  /// No description provided for @slaCriticalThreshold.
  ///
  /// In en, this message translates to:
  /// **'Critical Priority (Hours)'**
  String get slaCriticalThreshold;

  /// No description provided for @slaAutoEscalate.
  ///
  /// In en, this message translates to:
  /// **'Auto-escalation Policy'**
  String get slaAutoEscalate;

  /// No description provided for @kbSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search Knowledge Base...'**
  String get kbSearchPlaceholder;

  /// No description provided for @kbNoResults.
  ///
  /// In en, this message translates to:
  /// **'No articles found matching your criteria.'**
  String get kbNoResults;

  /// No description provided for @backupSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Synchronization'**
  String get backupSyncTitle;

  /// No description provided for @backupSyncStatusOverview.
  ///
  /// In en, this message translates to:
  /// **'Sync Status Overview'**
  String get backupSyncStatusOverview;

  /// No description provided for @backupLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync Date & Time'**
  String get backupLastSync;

  /// No description provided for @backupStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get backupStatusSynced;

  /// No description provided for @backupStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get backupStatusOffline;

  /// No description provided for @backupStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get backupStatusSyncing;

  /// No description provided for @backupStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get backupStatusFailed;

  /// No description provided for @backupPendingChanges.
  ///
  /// In en, this message translates to:
  /// **'Pending Changes'**
  String get backupPendingChanges;

  /// No description provided for @backupRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'Number of Synced Records'**
  String get backupRecordsCount;

  /// No description provided for @backupManualControls.
  ///
  /// In en, this message translates to:
  /// **'Manual Backup Controls'**
  String get backupManualControls;

  /// No description provided for @backupBtnBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup Now'**
  String get backupBtnBackupNow;

  /// No description provided for @backupBtnRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get backupBtnRestore;

  /// No description provided for @backupBtnDownload.
  ///
  /// In en, this message translates to:
  /// **'Download Backup File'**
  String get backupBtnDownload;

  /// No description provided for @backupSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Backup completed successfully'**
  String get backupSuccessMsg;

  /// No description provided for @backupAutoSettings.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync Settings'**
  String get backupAutoSettings;

  /// No description provided for @backupEnableAuto.
  ///
  /// In en, this message translates to:
  /// **'Enable Auto Sync'**
  String get backupEnableAuto;

  /// No description provided for @backupWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Sync on WiFi Only'**
  String get backupWifiOnly;

  /// No description provided for @backupSyncOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Sync on App Launch'**
  String get backupSyncOnLaunch;

  /// No description provided for @backupBackgroundSync.
  ///
  /// In en, this message translates to:
  /// **'Background Sync'**
  String get backupBackgroundSync;

  /// No description provided for @backupFrequencyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Backup Frequency Policy'**
  String get backupFrequencyPolicy;

  /// No description provided for @backupFreqRealtime.
  ///
  /// In en, this message translates to:
  /// **'Real-time'**
  String get backupFreqRealtime;

  /// No description provided for @backupFreq15m.
  ///
  /// In en, this message translates to:
  /// **'Every 15 minutes'**
  String get backupFreq15m;

  /// No description provided for @backupFreqHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get backupFreqHourly;

  /// No description provided for @backupFreqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get backupFreqDaily;

  /// No description provided for @backupFreqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get backupFreqWeekly;

  /// No description provided for @backupConflictRes.
  ///
  /// In en, this message translates to:
  /// **'Conflict Resolution Strategy'**
  String get backupConflictRes;

  /// No description provided for @backupConflictLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep Local Version'**
  String get backupConflictLocal;

  /// No description provided for @backupConflictServer.
  ///
  /// In en, this message translates to:
  /// **'Keep Server Version'**
  String get backupConflictServer;

  /// No description provided for @backupConflictMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge Automatically'**
  String get backupConflictMerge;

  /// No description provided for @backupDataScope.
  ///
  /// In en, this message translates to:
  /// **'Data Scope Selection'**
  String get backupDataScope;

  /// No description provided for @backupScopeAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get backupScopeAssets;

  /// No description provided for @backupScopeContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get backupScopeContracts;

  /// No description provided for @backupScopeTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get backupScopeTickets;

  /// No description provided for @backupScopeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get backupScopeSettings;

  /// No description provided for @backupScopeAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get backupScopeAudit;

  /// No description provided for @backupSecurityNotice.
  ///
  /// In en, this message translates to:
  /// **'Security & Encryption Notice'**
  String get backupSecurityNotice;

  /// No description provided for @backupSecurityDesc.
  ///
  /// In en, this message translates to:
  /// **'Data encryption in transit (TLS 1.3), Encrypted local & cloud storage (AES-256), Enterprise backup retention policy applied.'**
  String get backupSecurityDesc;

  /// No description provided for @backupCloudProvider.
  ///
  /// In en, this message translates to:
  /// **'Cloud Provider Section (Simulation)'**
  String get backupCloudProvider;

  /// No description provided for @backupStorageType.
  ///
  /// In en, this message translates to:
  /// **'Storage Type'**
  String get backupStorageType;

  /// No description provided for @backupTypeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local Only'**
  String get backupTypeLocal;

  /// No description provided for @backupTypeCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync (Simulated)'**
  String get backupTypeCloud;

  /// No description provided for @backupBtnConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Account'**
  String get backupBtnConnect;

  /// No description provided for @backupBtnDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Account'**
  String get backupBtnDisconnect;

  /// No description provided for @backupHistory.
  ///
  /// In en, this message translates to:
  /// **'Backup History'**
  String get backupHistory;

  /// No description provided for @backupHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backup history available.'**
  String get backupHistoryEmpty;

  /// No description provided for @chatMenuInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get chatMenuInfo;

  /// No description provided for @chatMenuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get chatMenuRename;

  /// No description provided for @chatMenuClear.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get chatMenuClear;

  /// No description provided for @chatMenuBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatMenuBlock;

  /// No description provided for @chatMenuUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get chatMenuUnblock;

  /// No description provided for @chatMenuClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get chatMenuClearConfirmTitle;

  /// No description provided for @chatMenuClearConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all messages? This action cannot be undone.'**
  String get chatMenuClearConfirmContent;

  /// No description provided for @chatMenuBlockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block / Unblock'**
  String get chatMenuBlockConfirmTitle;

  /// No description provided for @chatMenuBlockConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change the block status for this user?'**
  String get chatMenuBlockConfirmContent;

  /// No description provided for @chatMenuClearSuccess.
  ///
  /// In en, this message translates to:
  /// **'Chat cleared successfully'**
  String get chatMenuClearSuccess;

  /// No description provided for @chatMenuBlockSuccess.
  ///
  /// In en, this message translates to:
  /// **'Block status updated successfully'**
  String get chatMenuBlockSuccess;

  /// No description provided for @chatStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active Now'**
  String get chatStatusActive;

  /// No description provided for @chatStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get chatStatusOffline;

  /// No description provided for @chatVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get chatVoiceCall;

  /// No description provided for @chatVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get chatVideoCall;

  /// No description provided for @chatMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get chatMenuEdit;

  /// No description provided for @chatMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get chatMenuDelete;

  /// No description provided for @chatMenuDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get chatMenuDeleteConfirmTitle;

  /// No description provided for @chatMenuDeleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get chatMenuDeleteConfirmContent;

  /// No description provided for @chatMenuEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get chatMenuEditTitle;

  /// No description provided for @chatMenuEditHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new message text...'**
  String get chatMenuEditHint;

  /// No description provided for @chatMenuDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get chatMenuDeleteSuccess;

  /// No description provided for @chatMenuEditSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message updated'**
  String get chatMenuEditSuccess;

  /// No description provided for @chatMessageEdited.
  ///
  /// In en, this message translates to:
  /// **'(Edited)'**
  String get chatMessageEdited;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
