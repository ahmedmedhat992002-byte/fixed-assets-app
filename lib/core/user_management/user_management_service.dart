import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/data_utils.dart'; // Added for safe extraction

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a stream of users belonging to a specific company from `companies/{companyId}/users`.
  Stream<List<Map<String, dynamic>>> getCompanyUsersStream(String companyId) {
    if (companyId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {'uid': doc.id, ...data};
          }).toList();
        })
        .handleError((error) {
          debugPrint('Error fetching company users for $companyId: $error');
          return <Map<String, dynamic>>[];
        });
  }

  /// Fetches a specific user's detailed profile from `users/{uid}`.
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    if (uid.isEmpty) return {};
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching user profile for $uid: $e');
      return {};
    }
  }

  /// Updates a user's role in their main profile.
  /// NOTE: This will only work if the current user has permission (is admin).
  Future<void> updateUserRole(String uid, String newRole) async {
    if (uid.isEmpty) return;

    try {
      // 1. Update in main users collection
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. We should also update the company roster entry if it exists
      // However, we need the companyId. For now, let's assume the caller handles
      // or we fetch it first.
      final profile = await getUserProfile(uid);
      final companyId = DataUtils.asString(profile['companyId']);

      if (companyId.isNotEmpty) {
        await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('users')
            .doc(uid)
            .update({
              'role': newRole,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      debugPrint('Error updating user role for $uid: $e');
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Placeholder for adding a new user.
  /// In a real production app, this would likely call a Firebase Cloud Function
  /// to create the Auth user and then set the Firestore documents.
  Future<void> inviteUser({
    required String email,
    required String name,
    required String role,
    required String companyId,
  }) async {
    // This is a simplified implementation.
    // Ideally, this creates a record in an 'invitations' collection
    // which is then processed by a Cloud Function.
    try {
      final invitationId = _firestore.collection('invitations').doc().id;
      await _firestore.collection('invitations').doc(invitationId).set({
        'email': email.trim().toLowerCase(),
        'name': name.trim(),
        'role': role,
        'companyId': companyId,
        'status': 'pending',
        'invitedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending invitation: $e');
      throw Exception('Failed to send invitation');
    }
  }
}
