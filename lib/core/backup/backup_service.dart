import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';

/// Result returned after a backup attempt.
class BackupResult {
  const BackupResult({
    required this.timestamp,
    required this.recordCount,
    required this.fileSizeKb,
    required this.email,
  });

  final DateTime timestamp;
  final int recordCount;
  final double fileSizeKb;
  final String email;
}

/// Collects all user data from Firestore, serialises it to a JSON file,
/// and opens the OS share sheet so the user can send it via Gmail or any
/// other app.
class BackupService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Creates a backup JSON file and uploads it to Supabase Storage.
  ///
  /// Throws a [BackupException] on any failure so the caller can show a
  /// user-friendly error message.
  Future<BackupResult> createAndShareBackup() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const BackupException('User is not signed in.');
    }

    final uid = user.uid;
    final email = user.email ?? 'unknown@email.com';

    try {
      // ── 1. Fetch profile document ────────────────────────────────────────
      Map<String, dynamic> profileData = {};
      try {
        final profileDoc = await _db.collection('users').doc(uid).get();
        if (profileDoc.exists && profileDoc.data() != null) {
          profileData = _sanitiseFirestoreMap(profileDoc.data()!);
        }
      } catch (e) {
        debugPrint('[BackupService] Could not read profile: $e');
      }

      // ── 2. Fetch all assets ──────────────────────────────────────────────
      List<Map<String, dynamic>> assetsData = [];
      try {
        final assetsSnap = await _db.collection('users/$uid/assets').get();
        assetsData = assetsSnap.docs
            .map((d) => {'id': d.id, ..._sanitiseFirestoreMap(d.data())})
            .toList();
      } catch (e) {
        debugPrint('[BackupService] Could not read assets: $e');
      }

      // ── 3. Fetch contracts ───────────────────────────────────────────────
      List<Map<String, dynamic>> contractsData = [];
      try {
        final contractsSnap = await _db
            .collection('users/$uid/contracts')
            .get();
        contractsData = contractsSnap.docs
            .map((d) => {'id': d.id, ..._sanitiseFirestoreMap(d.data())})
            .toList();
      } catch (e) {
        debugPrint('[BackupService] Could not read contracts: $e');
      }

      // ── 4. Fetch transactions ────────────────────────────────────────────
      List<Map<String, dynamic>> transactionsData = [];
      try {
        final txSnap = await _db.collection('users/$uid/transactions').get();
        transactionsData = txSnap.docs
            .map((d) => {'id': d.id, ..._sanitiseFirestoreMap(d.data())})
            .toList();
      } catch (e) {
        debugPrint('[BackupService] Could not read transactions: $e');
      }

      // ── 5. Assemble payload ──────────────────────────────────────────────
      final now = DateTime.now();
      final payload = {
        'metadata': {
          'appName': 'WorldAssets',
          'backupDate': now.toIso8601String(),
          'userEmail': email,
          'totalRecords':
              assetsData.length +
              contractsData.length +
              transactionsData.length,
        },
        'profile': profileData,
        'assets': assetsData,
        'contracts': contractsData,
        'transactions': transactionsData,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(payload);

      // ── 6. Upload to Supabase Storage ────────────────────────────────────
      final dateStr =
          '${now.year}-${_pad(now.month)}-${_pad(now.day)}_${now.millisecondsSinceEpoch}';
      final fileName = 'worldassets_backup_$dateStr.json';
      final storagePath = '$uid/backups/$fileName';

      // Upload JSON directly as a string to avoid local file system limitations
      final fileData = utf8.encode(jsonString);
      final fileSizeKb = fileData.length / 1024;

      await Supabase.instance.client.storage
          .from(SupabaseConfig.chatBucket)
          .uploadBinary(
            storagePath,
            Uint8List.fromList(fileData),
            fileOptions: const FileOptions(
              contentType: 'application/json',
              upsert: true,
            ),
          );

      final totalRecords =
          assetsData.length + contractsData.length + transactionsData.length;

      return BackupResult(
        timestamp: now,
        recordCount: totalRecords,
        fileSizeKb: fileSizeKb,
        email: email,
      );
    } on BackupException {
      rethrow;
    } catch (e, st) {
      debugPrint('[BackupService] Unexpected error: $e\n$st');
      throw BackupException('Backup failed: ${e.toString()}');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Converts any Firestore-specific types (Timestamp, GeoPoint, etc.)
  /// to JSON-serialisable equivalents.
  Map<String, dynamic> _sanitiseFirestoreMap(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _sanitiseValue(value)));
  }

  dynamic _sanitiseValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is GeoPoint) {
      return {'lat': value.latitude, 'lng': value.longitude};
    }
    if (value is DocumentReference) return value.path;
    if (value is Map<String, dynamic>) return _sanitiseFirestoreMap(value);
    if (value is List) return value.map(_sanitiseValue).toList();
    return value;
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Thrown when an unrecoverable backup error occurs.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => 'BackupException: $message';
}
