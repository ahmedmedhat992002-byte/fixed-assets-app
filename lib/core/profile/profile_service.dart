import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../supabase/supabase_config.dart';
import 'models/profile_model.dart';

/// A dedicated service for fetching and updating user profile data from Firestore.
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;

  /// Returns a stream of the user's profile data from `users/{uid}`.
  Stream<ProfileModel?> getProfileStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);

    final user = FirebaseAuth.instance.currentUser;

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return ProfileModel.fromMap(
              snapshot.data()!,
              uid,
              authEmail: user?.email,
              authDisplayName: user?.displayName,
            );
          }
          return null;
        })
        .handleError((error) {
          debugPrint('Error fetching profile stream for $uid: $error');
          return null;
        });
  }

  /// Updates the user's profile data in Firestore `users/{uid}`.
  Future<void> updateProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? position,
    String? phone,
    String? phoneCode,
    String? photoUrl,
  }) async {
    if (uid.isEmpty) return;

    final Map<String, dynamic> data = {
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };

    if (firstName != null) data['firstName'] = firstName.trim();
    if (lastName != null) data['lastName'] = lastName.trim();
    if (position != null) data['position'] = position.trim();
    if (phone != null) data['phone'] = phone.trim();
    if (phoneCode != null) data['phoneCode'] = phoneCode.trim();
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('FirebaseException updating profile: ${e.message}');
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      debugPrint('Unknown error updating profile: $e');
      throw Exception('Failed to update profile.');
    }
  }

  /// Uploads a profile photo to Supabase Storage and returns the public URL.
  Future<String> uploadProfilePhoto(
    String uid,
    File file,
    String fileName,
  ) async {
    try {
      final String fileExt = fileName.split('.').last;
      final String path =
          'profiles/$uid/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage
          .from(SupabaseConfig.profilesBucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      return _supabase.storage
          .from(SupabaseConfig.profilesBucket)
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('ERROR: [ProfileService] uploadProfilePhoto failed: $e');
      throw Exception('Failed to upload profile photo to Supabase: $e');
    }
  }
}
