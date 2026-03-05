import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../sync/models/asset_local.dart';
import '../utils/data_utils.dart'; // Added for safe extraction
import 'models/dashboard_stats.dart';
import 'models/transaction_item.dart';

class DashboardService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DashboardStats> getDashboardStatsStream(String uid) {
    if (uid.isEmpty) return Stream.value(DashboardStats.empty());

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('assets')
        .snapshots()
        .map((snapshot) {
          double totalValue = 0.0;
          double totalDepreciation = 0.0;
          int assetsInMaintenance = 0;
          int disposedAssets = 0;
          int newAssetsThisPeriod = 0;

          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final status = DataUtils.asString(
              data['status'],
              'active',
            ).toLowerCase();

            if (status == 'maintenance') {
              assetsInMaintenance++;
            } else if (status == 'disposed') {
              disposedAssets++;
            }

            final createdAt = DataUtils.asTimestamp(data['createdAt']);
            if (createdAt != null && createdAt.toDate().isAfter(startOfMonth)) {
              newAssetsThisPeriod++;
            }

            final purchasePrice = DataUtils.asDouble(
              data['purchasePrice'] ?? data['value'],
            );
            final currentValue = DataUtils.asDouble(
              data['currentValue'] ?? purchasePrice,
            );

            totalValue += purchasePrice;

            final asset = AssetLocal(
              id: doc.id,
              companyId: DataUtils.asString(data['companyId'], uid),
              name: DataUtils.asString(data['name']),
              category: DataUtils.asString(data['category']),
              status: status,
              purchasePrice: purchasePrice,
              currentValue: currentValue,
              depreciationMethod: DataUtils.asString(
                data['depreciationMethod'],
                'None',
              ),
              version: DataUtils.asInt(data['version'], 1),
              updatedAtMs: DataUtils.asInt(data['updatedAtMs']),
              usefulLife: DataUtils.asInt(data['usefulLife']) > 0
                  ? DataUtils.asInt(data['usefulLife'])
                  : null,
              salvageValue: DataUtils.asDouble(data['salvageValue']),
              purchaseDateMs: DataUtils.asInt(data['purchaseDateMs']),
            );

            final manualDepreciation = purchasePrice - currentValue;
            final estimatedDepreciation = asset.getEstimatedDepreciation();

            totalDepreciation += math.max(
              manualDepreciation > 0 ? manualDepreciation : 0,
              estimatedDepreciation,
            );
          }

          final netValue = totalValue - totalDepreciation;

          return DashboardStats(
            totalValue: totalValue,
            totalDepreciation: totalDepreciation,
            netValue: netValue,
            assetsInMaintenance: assetsInMaintenance,
            newAssetsThisPeriod: newAssetsThisPeriod,
            disposedAssets: disposedAssets,
          );
        })
        .handleError((error) {
          debugPrint('DEBUG: Error in getDashboardStatsStream: $error');
          return DashboardStats.empty();
        });
  }

  Stream<List<AssetLocal>> getRecentlyAddedStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('assets')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return AssetLocal(
              id: doc.id,
              companyId: DataUtils.asString(data['companyId'], uid),
              name: DataUtils.asString(data['name'], 'Unknown Asset'),
              category: DataUtils.asString(data['category'], 'Uncategorized'),
              status: DataUtils.asString(data['status'], 'active'),
              purchasePrice: DataUtils.asDouble(data['purchasePrice']),
              currentValue: DataUtils.asDouble(data['currentValue']),
              depreciationMethod: DataUtils.asString(
                data['depreciationMethod'],
                'None',
              ),
              version: DataUtils.asInt(data['version'], 1),
              updatedAtMs: DataUtils.asInt(data['updatedAtMs']),
              location: DataUtils.asString(data['location']),
              assignedTo: DataUtils.asString(data['assignedTo']),
              description: DataUtils.asString(data['description']),
              usefulLife: DataUtils.asInt(data['usefulLife']) > 0
                  ? DataUtils.asInt(data['usefulLife'])
                  : null,
              salvageValue: DataUtils.asDouble(data['salvageValue']),
              purchaseDateMs: DataUtils.asInt(data['purchaseDateMs']),
              warrantyExpiryMs: DataUtils.asInt(data['warrantyExpiryMs']),
            );
          }).toList();
        })
        .handleError((error) {
          debugPrint('DEBUG: Error in getRecentlyAddedStream: $error');
          return <AssetLocal>[];
        });
  }

  Stream<List<AssetLocal>> getAssetsByCategoryStream(
    String uid,
    String category,
  ) {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('assets')
        .where('category', isEqualTo: category.toLowerCase())
        .snapshots()
        .map((snapshot) {
          final assets = snapshot.docs.map((doc) {
            final data = doc.data();
            return AssetLocal(
              id: doc.id,
              companyId: DataUtils.asString(data['companyId'], uid),
              name: DataUtils.asString(data['name'], 'Unknown Asset'),
              category: DataUtils.asString(data['category'], 'Uncategorized'),
              status: DataUtils.asString(data['status'], 'active'),
              purchasePrice: DataUtils.asDouble(data['purchasePrice']),
              currentValue: DataUtils.asDouble(data['currentValue']),
              depreciationMethod: DataUtils.asString(
                data['depreciationMethod'],
                'None',
              ),
              version: DataUtils.asInt(data['version'], 1),
              updatedAtMs: DataUtils.asInt(data['updatedAtMs']),
              location: DataUtils.asString(data['location']),
              assignedTo: DataUtils.asString(data['assignedTo']),
              description: DataUtils.asString(data['description']),
              usefulLife: DataUtils.asInt(data['usefulLife']) > 0
                  ? DataUtils.asInt(data['usefulLife'])
                  : null,
              salvageValue: DataUtils.asDouble(data['salvageValue']),
              purchaseDateMs: DataUtils.asInt(data['purchaseDateMs']),
              warrantyExpiryMs: DataUtils.asInt(data['warrantyExpiryMs']),
            );
          }).toList();
          assets.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
          return assets;
        })
        .handleError((error) {
          debugPrint('DEBUG: Error in getAssetsByCategoryStream: $error');
          return <AssetLocal>[];
        });
  }

  Stream<List<TransactionItem>> getLatestTransactionsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    print(
      'DEBUG: DashboardService - getLatestTransactionsStream called for $uid',
    );
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy(
          'date',
          descending: true,
        ) // Should be ordered by date or createdAt
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransactionItem.fromMap(doc.data(), doc.id))
              .toList();
        })
        .handleError((error) {
          print('DEBUG: Error in getLatestTransactionsStream: $error');
          return <TransactionItem>[];
        });
  }

  Stream<List<TransactionItem>> getAllTransactionsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    print('DEBUG: DashboardService - getAllTransactionsStream called for $uid');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransactionItem.fromMap(doc.data(), doc.id))
              .toList();
        })
        .handleError((error) {
          print('DEBUG: Error in getAllTransactionsStream: $error');
          return <TransactionItem>[];
        });
  }

  Future<bool> deleteAllTransactions(String uid) async {
    if (uid.isEmpty) return false;
    try {
      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions');
      final snapshot = await collection.get();

      if (snapshot.docs.isEmpty) return true;

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print(
        'DEBUG: DashboardService - Successfully deleted all ${snapshot.docs.length} transactions',
      );
      notifyListeners();
      return true;
    } catch (e) {
      print('DEBUG: Error in deleteAllTransactions: $e');
      return false;
    }
  }
}
