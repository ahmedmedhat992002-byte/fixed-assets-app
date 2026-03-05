import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../features/notifications/data/notification_service.dart';
import '../../features/notifications/data/notification_model.dart';

import 'models/contract_model.dart';

class ContractService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NotificationService? _notificationService;

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  String? lastError;

  /// Adds a new contract document to `users/{uid}/contracts/{contractId}`
  Future<bool> addContract(ContractModel contract) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      lastError = 'User not authenticated.';
      log('ContractService: $lastError');
      return false;
    }

    try {
      final docId = const Uuid().v4();
      final data = contract.toMap();

      // Ensure companyId binds to user uid if omitted
      if (data['companyId'] == null || data['companyId'].toString().isEmpty) {
        data['companyId'] = uid;
      }
      data['createdAtMs'] = DateTime.now().millisecondsSinceEpoch;
      if (data['status'] != null) {
        data['status'] = data['status'].toString().toLowerCase();
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('contracts')
          .doc(docId)
          .set(data);

      lastError = null;

      // Trigger Notification
      if (_notificationService != null) {
        await _notificationService!.sendSystemNotification(
          title: 'Contract Created',
          subtitle: 'A new contract for ${contract.vendor} was saved',
          body:
              'Contract "${contract.title}" with ${contract.vendor} has been successfully registered.',
          type:
              NotificationType.asset, // Reusing asset color/icon for contracts
        );
      }

      return true;
    } on FirebaseException catch (e) {
      log('ContractService Firestore Error: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        lastError = 'Permission denied. Please check your credentials.';
      } else {
        lastError = e.message ?? 'A Firestore error occurred.';
      }
      return false;
    } catch (e) {
      log('ContractService General Error: $e');
      lastError = 'An unexpected error occurred while adding the contract.';
      return false;
    }
  }

  /// Streams real-time contracts from `users/{uid}/contracts` ordered by `createdAtMs`
  Stream<List<ContractModel>> getContractsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('contracts')
        .orderBy('createdAtMs', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ContractModel.fromMap(doc.data(), doc.id);
          }).toList();
        })
        .handleError((error) {
          log('ContractService Error in getContractsStream: $error');
          return <ContractModel>[];
        });
  }
}
