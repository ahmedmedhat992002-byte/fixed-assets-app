import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../sync/models/asset_local.dart';
import '../transactions/transaction_service.dart';
import '../utils/data_utils.dart';
import '../../features/notifications/data/notification_service.dart';
import '../../features/notifications/data/notification_model.dart';

class AssetService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  TransactionService? _transactionService;
  NotificationService? _notificationService;

  void setTransactionService(TransactionService service) {
    _transactionService = service;
  }

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

  /// Adds a new asset to Firestore under the current user's scope.
  /// Requires an authenticated user.
  Future<bool> addAsset(AssetLocal asset) async {
    _setLoading(true);
    clearError();

    String path = 'unknown';
    Map<String, dynamic> payload = {};

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('DEBUG: User is not authenticated');
        throw Exception('User is not authenticated');
      }

      // Assign an ID if not already set, and default the companyId to the userId
      asset.id = asset.id.isEmpty ? const Uuid().v4() : asset.id;
      asset.companyId = user.uid;
      asset.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      asset.version = 1;

      // Construct the payload
      payload = asset.toMap();
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['category'] = asset.category.toLowerCase();
      payload['status'] = asset.status.toLowerCase();

      print(
        'DEBUG: Starting Firestore write for asset ${asset.id} under user ${user.uid}',
      );

      // Write to Firestore under the user-scoped assets sub-collection.
      path = 'users/${user.uid}/assets';
      await _firestore.collection(path).doc(asset.id).set(payload);

      print(
        'DEBUG: Successfully wrote asset ${asset.id} to Firestore at $path',
      );

      // Record transaction
      if (_transactionService != null) {
        await _transactionService!.recordTransaction(
          title: 'Purchased ${asset.name}',
          amount: asset.purchasePrice,
          type: 'purchase',
        );
      }

      // Record Notification
      if (_notificationService != null) {
        await _notificationService!.sendSystemNotification(
          title: 'Asset Added',
          subtitle: '${asset.name} has been successfully added',
          body:
              'A new ${asset.category} asset "${asset.name}" has been registered in the system.',
          type: NotificationType.asset,
        );
      }

      return true;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print(
          'DEBUG: [AssetService] Firestore write failed: [${e.code}] ${e.message}',
        );
        print('DEBUG: [AssetService] Targeted Path: $path');
        print('DEBUG: [AssetService] Payload: $payload');
      }
      if (e.code == 'permission-denied') {
        _lastError = 'You do not have permission to add assets.';
      } else {
        _lastError = 'Firebase Error: ${e.message}';
      }
      return false;
    } catch (e) {
      _lastError = 'Error adding asset: $e';
      return false;
    } finally {
      print('DEBUG: addAsset operation completed, setting loading to false');
      _setLoading(false);
    }
  }

  /// Updates an existing asset in Firestore.
  Future<bool> updateAsset(AssetLocal asset) async {
    _setLoading(true);
    clearError();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      asset.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      asset.version = (asset.version) + 1;

      final payload = asset.toMap();
      payload['category'] = asset.category.toLowerCase();
      payload['status'] = asset.status.toLowerCase();

      await _firestore
          .collection('users/${user.uid}/assets')
          .doc(asset.id)
          .update(payload);

      print('DEBUG: Successfully updated asset ${asset.id}');

      // Record Notification
      if (_notificationService != null) {
        await _notificationService!.sendSystemNotification(
          title: 'Asset Updated',
          subtitle: '${asset.name} has been modified',
          body: 'The asset "${asset.name}" has been updated in the system.',
          type: NotificationType.asset,
        );
      }

      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _lastError = 'You do not have permission to update assets.';
      } else {
        _lastError = 'Firebase Error: ${e.message}';
      }
      return false;
    } catch (e) {
      _lastError = 'Error updating asset: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes an asset from Firestore under the current user's scope.
  Future<bool> deleteAsset(String assetId) async {
    _setLoading(true);
    clearError();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      await _firestore
          .collection('users/${user.uid}/assets')
          .doc(assetId)
          .delete();

      print('DEBUG: Successfully deleted asset $assetId');

      // Record transaction (Disposal)
      if (_transactionService != null) {
        await _transactionService!.recordTransaction(
          title:
              'Disposed asset $assetId', // Ideally we'd have the name, but this works
          amount:
              0.0, // Disposal value could be added to the deleteAsset method
          type: 'disposal',
        );
      }

      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _lastError = 'You do not have permission to delete assets.';
      } else {
        _lastError = 'Firebase Error: ${e.message}';
      }
      return false;
    } catch (e) {
      _lastError = 'Error deleting asset: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes ALL assets for the current user in a batch.
  Future<bool> deleteAllAssets() async {
    _setLoading(true);
    clearError();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      final path = 'users/${user.uid}/assets';
      final snapshot = await _firestore.collection(path).get();

      if (snapshot.docs.isEmpty) {
        return true;
      }

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('DEBUG: Successfully deleted all ${snapshot.docs.length} assets');
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _lastError = 'You do not have permission to perform bulk delete.';
      } else {
        _lastError = 'Firebase Error: ${e.message}';
      }
      return false;
    } catch (e) {
      _lastError = 'Error during bulk delete: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  AssetLocal _mapToAsset(String id, Map<String, dynamic> data, String uid) {
    return AssetLocal.fromMap(data, id, uid);
  }

  /// Find an asset by name or ID (case-insensitive for name).
  Future<AssetLocal?> findAssetByNameOrId(String query) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final trimmedQuery = query.trim();
    final lowerQuery = trimmedQuery.toLowerCase();

    try {
      // 1. Try by ID first
      final idDoc = await _firestore
          .collection('users/${user.uid}/assets')
          .doc(trimmedQuery)
          .get();
      if (idDoc.exists && idDoc.data() != null) {
        return _mapToAsset(idDoc.id, idDoc.data()!, user.uid);
      }

      // 2. Try by Name (Case-insensitive)
      final snapshot = await _firestore
          .collection('users/${user.uid}/assets')
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = DataUtils.asString(data['name']).toLowerCase();
        if (name == lowerQuery) {
          return _mapToAsset(doc.id, data, user.uid);
        }
      }
    } catch (e) {
      print('DEBUG: Error in findAssetByNameOrId: $e');
    }
    return null;
  }

  /// Updates the asset's real-time location and last scanned timestamp.
  Future<bool> updateAssetLocation({
    required String assetId,
    required double latitude,
    required double longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _firestore
          .collection('users/${user.uid}/assets')
          .doc(assetId)
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'lastScannedAtMs': now,
            'updatedAtMs': now,
          });

      print(
        'DEBUG: Updated location for asset $assetId: ($latitude, $longitude)',
      );
      return true;
    } catch (e) {
      print('DEBUG: Error updating asset location: $e');
      return false;
    }
  }

  /// Stream of assets for the current user and specified category.
  /// Useful for real-time UI updates (e.g., in a list screen).
  Stream<List<AssetLocal>> getAssetsStream(String category) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users/${user.uid}/assets')
        .where('category', isEqualTo: category.toLowerCase())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return _mapToAsset(doc.id, doc.data(), user.uid);
          }).toList();
        })
        .handleError((error) {
          return <AssetLocal>[];
        });
  }

  /// Reusable method to stream assets by category for a given user.
  Stream<List<AssetLocal>> getAssetsByCategory(String uid, String category) {
    return _firestore
        .collection('users/$uid/assets')
        .where('category', isEqualTo: category.toLowerCase())
        .snapshots()
        .map((snapshot) {
          final assets = snapshot.docs.map((doc) {
            return _mapToAsset(doc.id, doc.data(), uid);
          }).toList();
          assets.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
          return assets;
        })
        .handleError((error) {
          return <AssetLocal>[];
        });
  }

  /// Stream of ALL assets for a given user.
  Stream<List<AssetLocal>> getAllAssetsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users/$uid/assets')
        .snapshots()
        .map((snapshot) {
          final assets = snapshot.docs.map((doc) {
            return _mapToAsset(doc.id, doc.data(), uid);
          }).toList();
          // Sort by latest update
          assets.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
          return assets;
        })
        .handleError((error) {
          debugPrint('Error in getAllAssetsStream: $error');
          return <AssetLocal>[];
        });
  }
}
