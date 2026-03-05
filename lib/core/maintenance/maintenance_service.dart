import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../sync/models/maintenance_local.dart';
import '../../features/notifications/data/notification_service.dart';
import '../../features/notifications/data/notification_model.dart';

class MaintenanceService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  NotificationService? _notificationService;

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Streams maintenance records for the current user, optionally filtered by asset.
  Stream<List<MaintenanceLocal>> getMaintenanceStream({String? assetId}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _firestore.collection('users/${user.uid}/maintenance');

    if (assetId != null) {
      query = query.where('assetId', isEqualTo: assetId);
    }

    return query
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return MaintenanceLocal.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
          list.sort((a, b) => b.dateMs.compareTo(a.dateMs));
          return list;
        })
        .handleError((error) {
          debugPrint('[MaintenanceService] Stream error: $error');
          return <MaintenanceLocal>[];
        });
  }

  /// Adds a new maintenance record.
  Future<bool> addMaintenance(MaintenanceLocal record) async {
    _setLoading(true);
    clearError();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final id = record.id.isEmpty ? const Uuid().v4() : record.id;
      record.id = id;
      record.updatedAtMs = DateTime.now().millisecondsSinceEpoch;

      final payload = record.toMap();
      payload['createdAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users/${user.uid}/maintenance')
          .doc(id)
          .set(payload);

      // Trigger Notification
      if (_notificationService != null) {
        await _notificationService!.sendSystemNotification(
          title: 'Maintenance Logged',
          subtitle: 'Maintenance for ${record.assetName} saved',
          body:
              'A ${record.type} maintenance record for "${record.assetName}" with status ${record.status} has been registered.',
          type: NotificationType.achievement, // Use green achievement color
        );
      }

      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[MaintenanceService] Error adding maintenance: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes a maintenance record.
  Future<bool> deleteMaintenance(String id) async {
    _setLoading(true);
    clearError();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users/${user.uid}/maintenance')
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
