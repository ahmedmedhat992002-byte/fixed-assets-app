import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_model.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Stream<List<NotificationModel>> getNotificationsStream() {
    final uid = _userId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<int> getUnreadCountStream() {
    final uid = _userId;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _userId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final uid = _userId;
    if (uid == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    final uid = _userId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// Adds a notification for the current user.
  /// This can be called from other services (e.g., when an asset is added).
  Future<void> addNotification(NotificationModel notification) async {
    final uid = _userId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notification.id.isEmpty ? null : notification.id)
        .set(notification.toMap());
  }

  /// Helper to create a specific notification
  Future<void> sendSystemNotification({
    required String title,
    required String subtitle,
    required String body,
    required NotificationType type,
    String? routeName,
    Map<String, dynamic>? routeArgs,
  }) async {
    final notification = NotificationModel(
      id: '', // Firestore will generate ID if we pass empty/null to addNotification logic
      title: title,
      subtitle: subtitle,
      body: body,
      date: DateTime.now(),
      type: type,
      routeName: routeName,
      routeArgs: routeArgs,
    );
    await addNotification(notification);
  }

  /// Adds a notification for a SPECIFIC user.
  /// Used for cross-user notifications like Chat.
  Future<void> addNotificationToUser(
    String targetUid,
    NotificationModel notification,
  ) async {
    if (targetUid.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .doc(notification.id.isEmpty ? null : notification.id)
        .set(notification.toMap());
  }

  /// Helper to send a system notification to a SPECIFIC user.
  Future<void> sendSystemNotificationToUser({
    required String targetUid,
    required String title,
    required String subtitle,
    required String body,
    required NotificationType type,
    String? routeName,
    Map<String, dynamic>? routeArgs,
  }) async {
    final notification = NotificationModel(
      id: '',
      title: title,
      subtitle: subtitle,
      body: body,
      date: DateTime.now(),
      type: type,
      routeName: routeName,
      routeArgs: routeArgs,
    );
    await addNotificationToUser(targetUid, notification);
  }
}
