import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM token management + push notification delivery.
class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isLocalNotificationsInitialized = false;

  /// Initializes local notifications for foreground display.
  Future<void> _initLocalNotifications() async {
    if (_isLocalNotificationsInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
      },
    );

    _isLocalNotificationsInitialized = true;
  }

  /// Must be called once when the user is signed in.
  /// Requests notification permission and saves the FCM token to Firestore.
  Future<void> initForUser(String uid) async {
    if (uid.isEmpty) return;

    try {
      // 1. Request Android 13+ permission
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.notification.request();
      }

      // 2. Request FCM permission
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Get and save Token
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('fcmTokens')
            .doc(token)
            .set({
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        });

        // 4. Listen for token refresh
        _fcm.onTokenRefresh.listen((newToken) {
          _firestore
              .collection('users')
              .doc(uid)
              .collection('fcmTokens')
              .doc(newToken)
              .set({
            'token': newToken,
            'updatedAt': FieldValue.serverTimestamp(),
            'platform': defaultTargetPlatform.name,
          });
        });
      }
    } catch (e) {
      // Silent error in production to avoid bothering user
    }
  }

  /// Listens for messages when the app is in the foreground.
  void listenToForegroundMessages() {
    _initLocalNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      RemoteNotification? notification = message.notification;

      // If `onMessage` is triggered, we show a local notification
      // to create a "Heads Up" effect while the app is open.
      if (notification != null && !kIsWeb) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // id
              'High Importance Notifications', // title
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['chatId'], // Example payload
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
    });
  }

  /// Removes the current device token when the user signs out.
  Future<void> removeTokenForUser(String uid) async {
    if (uid.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('fcmTokens')
            .doc(token)
            .delete();
      }
    } catch (e) {
      // Silent error
    }
  }

  /// Fetches FCM tokens from Firestore and invokes the Supabase Edge Function
  /// `send-fcm` to securely deliver the notification.
  Future<void> sendPushToUser({
    required String targetUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (targetUid.isEmpty) return;
    try {
      // 1. Fetch the user's tokens from Firestore
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(targetUid)
          .collection('fcmTokens')
          .get();

      if (tokensSnapshot.docs.isEmpty) return;

      final tokens = tokensSnapshot.docs
          .map((doc) => doc.data()['token'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .toList();

      if (tokens.isEmpty) return;

      // 2. Invoke the Supabase Edge Function
      await Supabase.instance.client.functions.invoke(
        'send-fcm',
        body: {
          'tokens': tokens,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
    } catch (e) {
      // Silent error
    }
  }
}
