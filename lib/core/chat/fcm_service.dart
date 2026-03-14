import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  
  /// The ID of the chat currently being viewed by the user.
  /// Notifications for this chat will be suppressed in the foreground.
  String? activeChatId;

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

    // Create the channel on Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'high_importance_channel',
            'High Importance Notifications',
            description: 'This channel is used for important notifications.',
            importance: Importance.max,
          ));
    }

    _isLocalNotificationsInitialized = true;
  }

  /// Must be called once when the user is signed in.
  /// Requests notification permission and saves the FCM token to Firestore.
  Future<void> initForUser(String uid) async {
    if (uid.isEmpty) return;
    
    // Ensure the Android notification channel exists at startup. 
    // This allows background high-priority FCM notifications to display natively 
    // without manual code interception.
    await _initLocalNotifications();

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

      // Extract chatId and acknowledge delivery immediately
      final chatId = message.data['chatId'];
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (chatId != null && uid != null) {
        _markAsDeliveredDirectly(chatId, uid);
      }

      // If `onMessage` is triggered, we show a local notification
      // to create a "Heads Up" effect while the app is open.
      // WE FILTER it if the user is already inside THIS chat.
      if (notification != null && !kIsWeb && chatId != activeChatId) {
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

  /// Directly updates messages to 'delivered' status in Firestore.
  /// This is used for immediate delivery acknowledgement.
  Future<void> _markAsDeliveredDirectly(String chatId, String uid) async {
    try {
      final db = FirebaseFirestore.instance;
      // Immediate chat doc update
      await db.collection('chats').doc(chatId).update({
        'lastMessageStatus': 'delivered'
      });

      // Update individual messages
      final messages = await db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('status', isEqualTo: 'sent')
          .get();

      if (messages.docs.isNotEmpty) {
        final batch = db.batch();
        bool updated = false;
        for (var doc in messages.docs) {
          if (doc.data()['senderId'] != uid) {
            batch.update(doc.reference, {'status': 'delivered'});
            updated = true;
          }
        }
        if (updated) await batch.commit();
      }
    } catch (e) {
      debugPrint('Error acknowledging delivery: $e');
    }
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

  /// Helper for remote diagnostics (writes to Firestore debug_logs)
  Future<void> logRemote(String message, {Object? error}) async {
    try {
      if (kDebugMode) debugPrint('REMOTE_LOG: $message');
      await _firestore.collection('debug_logs').add({
        'message': message,
        'error': error?.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      });
    } catch (e) {
      debugPrint('FAILED TO LOG REMOTE: $e');
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
    await logRemote('FCM: Starting sendPushToUser for $targetUid');
    
    try {
      // 1. Fetch the user's tokens from Firestore
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(targetUid)
          .collection('fcmTokens')
          .get();

      if (tokensSnapshot.docs.isEmpty) {
        await logRemote('FCM: No tokens found for $targetUid');
        return;
      }
      
      final tokens = tokensSnapshot.docs
          .map((doc) => doc.data()['token'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .toList();

      await logRemote('FCM: Found ${tokens.length} tokens for $targetUid');

      if (tokens.isEmpty) return;

      // 2. Invoke the Supabase Edge Function
      await logRemote('FCM: Invoking send-fcm for ${tokens.length} tokens');
      
      final res = await Supabase.instance.client.functions.invoke(
        'send-fcm',
        body: {
          'tokens': tokens,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      
      await logRemote('FCM: Supabase response status ${res.status}');
      debugPrint('FCM Response from Supabase: ${res.status} - ${res.data}');
    } catch (e, stack) {
      await logRemote('FCM CRITICAL ERROR: $e', error: e);
      debugPrint('FCM CRITICAL ERROR: $e');
      debugPrint('FCM STACKTRACE: $stack');
    }
  }
}
