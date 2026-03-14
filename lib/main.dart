import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'package:assets_management/app/app.dart';
import 'package:assets_management/core/auth/auth_service.dart';
import 'package:assets_management/core/locale/locale_controller.dart';
import 'package:assets_management/core/sync/hive_service.dart';
import 'package:assets_management/core/theme/theme_controller.dart';
import 'package:assets_management/core/supabase/supabase_config.dart';
import 'package:assets_management/features/settings/data/notification_settings_controller.dart';
import 'package:assets_management/features/settings/data/security_settings_controller.dart';
import 'package:assets_management/core/chat/fcm_service.dart';



const _iosOptions = FirebaseOptions(
  apiKey: 'AIzaSyCn_1s2bFqrjLFe2JEaQYSE8erJ1_piM8w',
  appId: '1:364117275125:ios:7b106d4c9cc8f837f4f0bc',
  messagingSenderId: '364117275125',
  projectId: 'fixed-asset-af615',
  storageBucket: 'fixed-asset-af615.firebasestorage.app',
  iosBundleId: 'com.example.assetsManagement',
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Platform.isIOS) {
    await Firebase.initializeApp(options: _iosOptions);
  } else {
    await Firebase.initializeApp();
  }
  
  // The system natively handles displaying messages that contain a `notification`
  // payload when the app is in the background or killed. 
  // We do not need to manually trigger FlutterLocalNotificationsPlugin.show()
  // for these messages because it'll cause duplicates or crash on iOS.
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Explicit options for iOS. Android relies on google-services.json natively
  // for Firebase Cloud Messaging to work correctly.
  if (Platform.isIOS) {
    await Firebase.initializeApp(options: _iosOptions);
  } else {
    await Firebase.initializeApp();
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await FcmService().logRemote('APPBOOT: Project initialized');

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await HiveService.init();

  final authService = AuthService()..initialize();
  final localeController = await LocaleController.create();
  final themeController = await ThemeController.create();
  final notificationSettingsController =
      await NotificationSettingsController.create();
  final securitySettingsController = await SecuritySettingsController.create();

  runApp(
    App(
      authService: authService,
      localeController: localeController,
      themeController: themeController,
      notificationSettingsController: notificationSettingsController,
      securitySettingsController: securitySettingsController,
    ),
  );
}
