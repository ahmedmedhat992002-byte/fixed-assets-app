import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:assets_management/app/app.dart';
import 'package:assets_management/core/auth/auth_service.dart';
import 'package:assets_management/core/locale/locale_controller.dart';
import 'package:assets_management/core/sync/hive_service.dart';
import 'package:assets_management/core/theme/theme_controller.dart';
import 'package:assets_management/core/supabase/supabase_config.dart';
import 'package:assets_management/features/settings/data/notification_settings_controller.dart';
import 'package:assets_management/features/settings/data/security_settings_controller.dart';

/// Firebase options sourced directly from android/app/google-services.json.
///
/// This approach bypasses the google-services Gradle plugin and the
/// values.xml resource lookup entirely — no FlutterFire CLI required.
///
/// Values from google-services.json:
///   project_id       → fixed-asset-af615
///   project_number   → 364117275125        (messagingSenderId)
///   mobilesdk_app_id → 1:364117275125:android:01c6675a46beb534f4f0bc
///   api_key          → AIzaSyAweCMh8LEPU_MyCC2u5M2jyTFjCoYOtdg
///   storage_bucket   → fixed-asset-af615.firebasestorage.app
const _androidOptions = FirebaseOptions(
  apiKey: 'AIzaSyAweCMh8LEPU_MyCC2u5M2jyTFjCoYOtdg',
  appId: '1:364117275125:android:01c6675a46beb534f4f0bc',
  messagingSenderId: '364117275125',
  projectId: 'fixed-asset-af615',
  storageBucket: 'fixed-asset-af615.firebasestorage.app',
);

const _iosOptions = FirebaseOptions(
  apiKey: 'AIzaSyCn_1s2bFqrjLFe2JEaQYSE8erJ1_piM8w',
  appId: '1:364117275125:ios:7b106d4c9cc8f837f4f0bc',
  messagingSenderId: '364117275125',
  projectId: 'fixed-asset-af615',
  storageBucket: 'fixed-asset-af615.firebasestorage.app',
  iosBundleId: 'com.example.assetsManagement',
);

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Using correct options per platform prevents native crashes at boot.
    await Firebase.initializeApp(
      options: Platform.isIOS ? _iosOptions : _androidOptions,
    );

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

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
  } catch (e, stack) {
    debugPrint('FATAL INIT ERROR: $e\n$stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                'App Initialization Failed:\n\n$e\n\n$stack',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
