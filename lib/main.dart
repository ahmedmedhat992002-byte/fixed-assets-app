import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:assets_management/app/app.dart';
import 'package:assets_management/core/auth/auth_service.dart';
import 'package:assets_management/core/locale/locale_controller.dart';
import 'package:assets_management/core/sync/hive_service.dart';
import 'package:assets_management/core/theme/theme_controller.dart';
import 'package:assets_management/core/supabase/supabase_config.dart';
import 'package:assets_management/features/settings/data/notification_settings_controller.dart';
import 'package:assets_management/features/settings/data/security_settings_controller.dart';



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
  await Firebase.initializeApp();
  
  // If the message has a notification or data, we can show it via local notifications.
  // This is especially important for "data-only" messages or to ensure 
  // the high_importance_channel is respected.
  final notification = message.notification;
  final data = message.data;

  if (notification != null || data.isNotEmpty) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    await flutterLocalNotificationsPlugin.show(
      id: notification?.hashCode ?? 0,
      title: notification?.title ?? data['title'] ?? 'New Message',
      body: notification?.body ?? data['body'] ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
  
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
