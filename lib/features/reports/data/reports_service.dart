import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/sync/models/asset_local.dart';
import '../../../core/sync/models/maintenance_local.dart';
import '../../../core/utils/data_utils.dart'; // Added for safe extraction

class ReportsData {
  final int totalAssets;
  final double assetGrowth;
  final Map<String, int> assetsByCategory;

  final int totalMaintenance;
  final double maintenanceGrowth;
  final Map<String, int> maintenanceByType;

  final double totalPurchaseValue;
  final double totalMaintenanceCost;
  final double totalDepreciation;
  final double totalDisposalValue;
  final int assetsInMaintenance;
  final int newAssetsThisPeriod;
  final int disposedAssets;
  final List<AssetLocal> allAssets; // For exporting the full register
  final List<MaintenanceLocal>
  allMaintenance; // For exporting the full register

  ReportsData({
    required this.totalAssets,
    required this.assetGrowth,
    required this.assetsByCategory,
    required this.totalMaintenance,
    required this.maintenanceGrowth,
    required this.maintenanceByType,
    required this.totalPurchaseValue,
    required this.totalMaintenanceCost,
    required this.totalDepreciation,
    required this.totalDisposalValue,
    this.assetsInMaintenance = 0,
    this.newAssetsThisPeriod = 0,
    this.disposedAssets = 0,
    this.allAssets = const [],
    this.allMaintenance = const [],
  });
}

class GeneratedReport {
  final String id;
  final String title;
  final String type;
  final String period;
  final DateTime generatedAt;
  final String subtitle;
  final bool isGenerating;
  final String? fileUrl;

  GeneratedReport({
    required this.id,
    required this.title,
    required this.type,
    required this.period,
    required this.generatedAt,
    required this.subtitle,
    required this.isGenerating,
    this.fileUrl,
  });

  factory GeneratedReport.fromMap(String id, Map<String, dynamic> map) {
    return GeneratedReport(
      id: id,
      title: DataUtils.asString(map['title'], 'Unknown Report'),
      type: DataUtils.asString(map['type'], 'PDF'),
      period: DataUtils.asString(map['period'], 'Unknown Period'),
      generatedAt: DataUtils.asDateTime(map['generatedAt']),
      subtitle: DataUtils.asString(map['subtitle']),
      isGenerating: DataUtils.asBool(map['isGenerating']),
      fileUrl: DataUtils.asString(map['fileUrl']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'period': period,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'subtitle': subtitle,
      'isGenerating': isGenerating,
      'fileUrl': fileUrl,
    };
  }
}

class ReportSummary {
  final int totalReports;
  final int thisMonthReports;
  final int scheduledReports;
  final int automatedReports;

  ReportSummary({
    required this.totalReports,
    required this.thisMonthReports,
    required this.scheduledReports,
    required this.automatedReports,
  });
}

class ReportsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache user ref
  DocumentReference? get _userDoc {
    final user = _auth.currentUser;
    return user != null ? _firestore.collection('users').doc(user.uid) : null;
  }

  // Calculate Date Range based on Period Filter
  (DateTime start, DateTime end, DateTime prevStart, DateTime prevEnd)
  _getDateRanges(String period) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;
    DateTime prevStart;
    DateTime prevEnd;

    switch (period) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        prevStart = start.subtract(const Duration(days: 1));
        prevEnd = start.subtract(const Duration(microseconds: 1));
        break;
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        prevStart = start.subtract(const Duration(days: 7));
        prevEnd = start.subtract(const Duration(microseconds: 1));
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        prevStart = DateTime(now.year, now.month - 1, 1);
        prevEnd = start.subtract(const Duration(microseconds: 1));
        break;
      case 'This Quarter':
        final currentQuarter = (now.month - 1) ~/ 3 + 1;
        start = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);
        prevStart = DateTime(now.year, (currentQuarter - 2) * 3 + 1, 1);
        prevEnd = start.subtract(const Duration(microseconds: 1));
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        prevStart = DateTime(now.year - 1, 1, 1);
        prevEnd = start.subtract(const Duration(microseconds: 1));
        break;
      case 'All':
        start = DateTime(2000);
        prevStart = DateTime(1999);
        prevEnd = start.subtract(const Duration(microseconds: 1));
        break;
      default:
        start = DateTime(now.year, now.month, 1);
        prevStart = DateTime(now.year, now.month - 1, 1);
        prevEnd = start.subtract(const Duration(microseconds: 1));
    }
    return (start, end, prevStart, prevEnd);
  }

  double _calculateGrowth(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  Future<ReportsData> fetchReportsData(String period) async {
    final docRef = _userDoc;
    if (docRef == null) {
      throw Exception('User is not authenticated');
    }

    final uid = docRef.id;

    final ranges = _getDateRanges(period);
    final start = ranges.$1;
    final end = ranges.$2;
    final prevStart = ranges.$3;
    final prevEnd = ranges.$4;

    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);
    final prevStartTs = Timestamp.fromDate(prevStart);
    final prevEndTs = Timestamp.fromDate(prevEnd);

    int currentAssets = 0;
    int previousAssets = 0;
    int assetsInMaintenance = 0;
    int disposedAssets = 0;
    int newAssetsThisPeriod = 0;

    Map<String, int> assetsByCategory = {
      'machinery': 0,
      'vehicles': 0,
      'furniture': 0,
      'computer hardware': 0,
      'computer software': 0,
      'fixed assets': 0,
      'intangible': 0,
    };
    double totalPurchaseValue = 0;
    List<AssetLocal> allAssets = [];

    int currentMaint = 0;
    int prevMaint = 0;
    Map<String, int> maintenanceByType = {
      'preventive': 0,
      'corrective': 0,
      'emergency': 0,
      'scheduled': 0,
    };
    double totalMaintenanceCost = 0;
    List<MaintenanceLocal> allMaintenance = [];

    double totalDepreciation = 0;
    double totalDisposalValue = 0;

    // 1. ASSETS
    try {
      final assetsSnap = await _firestore.collection('users/$uid/assets').get();

      for (var doc in assetsSnap.docs) {
        final data = doc.data();
        final createdAt = DataUtils.asTimestamp(data['createdAt']);
        final status = DataUtils.asString(
          data['status'],
          'active',
        ).toLowerCase();

        if (status == 'maintenance') {
          assetsInMaintenance++;
        } else if (status == 'disposed') {
          disposedAssets++;
        }

        if (createdAt != null) {
          if (createdAt.compareTo(startTs) >= 0 &&
              createdAt.compareTo(endTs) <= 0) {
            currentAssets++;
            newAssetsThisPeriod++;

            final category = DataUtils.asString(data['category']).toLowerCase();
            if (assetsByCategory.containsKey(category)) {
              assetsByCategory[category] = assetsByCategory[category]! + 1;
            }
          } else if (createdAt.compareTo(prevStartTs) >= 0 &&
              createdAt.compareTo(prevEndTs) <= 0) {
            previousAssets++;
          }
        }

        final purchasePrice = DataUtils.asDouble(
          data['purchasePrice'] ?? data['value'],
        );

        totalPurchaseValue += purchasePrice;

        final currentValue = DataUtils.asDouble(
          data['currentValue'] ?? purchasePrice,
        );

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
          usefulLife: data['usefulLife'] as int?,
          salvageValue: DataUtils.asDouble(data['salvageValue']),
          purchaseDateMs: DataUtils.asInt(data['purchaseDateMs']),
          location: data['location'] as String?,
          department: data['department'] as String?,
          vendor: data['vendor'] as String?,
        );

        allAssets.add(asset);

        final manualDep = purchasePrice - currentValue;
        totalDepreciation += math.max(
          manualDep > 0 ? manualDep : 0,
          asset.getEstimatedDepreciation(),
        );

        if (status == 'disposed') {
          totalDisposalValue += currentValue;
        }
      }
    } catch (e) {
      // Silenced as requested
    }

    // 2. MAINTENANCE
    try {
      final maintenanceSnap = await _firestore
          .collection('users/$uid/maintenance')
          .get();

      for (var doc in maintenanceSnap.docs) {
        final data = doc.data();
        final date = DataUtils.asTimestamp(data['date'] ?? data['createdAt']);

        final maintItem = MaintenanceLocal.fromMap(doc.id, data);
        allMaintenance.add(maintItem);

        if (date != null) {
          if (date.compareTo(startTs) >= 0 && date.compareTo(endTs) <= 0) {
            currentMaint++;

            final type = DataUtils.asString(data['type']).toLowerCase();
            if (maintenanceByType.containsKey(type)) {
              maintenanceByType[type] = maintenanceByType[type]! + 1;
            }

            totalMaintenanceCost += DataUtils.asDouble(data['cost']);
          } else if (date.compareTo(prevStartTs) >= 0 &&
              date.compareTo(prevEndTs) <= 0) {
            prevMaint++;
          }
        }
      }
    } catch (e) {
      // Silenced as requested
    }

    // 3. TRANSACTIONS (Financials) - Optional override if transactions exist
    try {
      final transactionsSnap = await _firestore
          .collection('users/$uid/transactions')
          .get();

      for (var doc in transactionsSnap.docs) {
        final data = doc.data();
        final date = DataUtils.asTimestamp(data['date'] ?? data['createdAt']);
        if (date != null &&
            date.compareTo(startTs) >= 0 &&
            date.compareTo(endTs) <= 0) {
          final type = DataUtils.asString(data['type']).toLowerCase();
          final val = DataUtils.asDouble(data['value']);

          // Transactions might provide more accurate financial data for a specific period
          if (type == 'depreciation') totalDepreciation += val;
          if (type == 'disposal') totalDisposalValue += val;
        }
      }
    } catch (e) {
      // Silenced as requested
    }

    return ReportsData(
      totalAssets: currentAssets,
      assetGrowth: _calculateGrowth(currentAssets, previousAssets),
      assetsByCategory: assetsByCategory,
      totalMaintenance: currentMaint,
      maintenanceGrowth: _calculateGrowth(currentMaint, prevMaint),
      maintenanceByType: maintenanceByType,
      totalPurchaseValue: totalPurchaseValue,
      totalMaintenanceCost: totalMaintenanceCost,
      totalDepreciation: totalDepreciation,
      totalDisposalValue: totalDisposalValue,
      assetsInMaintenance: assetsInMaintenance,
      newAssetsThisPeriod: newAssetsThisPeriod,
      disposedAssets: disposedAssets,
      allAssets: allAssets,
      allMaintenance: allMaintenance,
    );
  }

  Stream<List<GeneratedReport>> getRecentReportsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    final path = 'users/$uid/reports';

    return _firestore
        .collection(path)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => GeneratedReport.fromMap(doc.id, doc.data()))
              .toList(),
        )
        .handleError((e) {
          // Silenced as requested
          return <GeneratedReport>[];
        });
  }

  Stream<ReportSummary> getReportSummaryStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(
        ReportSummary(
          totalReports: 0,
          thisMonthReports: 0,
          scheduledReports: 0,
          automatedReports: 0,
        ),
      );
    }

    return _firestore
        .collection('users/$uid/reports')
        .snapshots()
        .map((snap) {
          final now = DateTime.now();
          int total = 0;
          int thisMonth = 0;
          int scheduled = 0;
          int automated = 0;

          for (var doc in snap.docs) {
            total++;
            final data = doc.data();
            final date = (data['generatedAt'] as Timestamp?)?.toDate();
            if (date != null &&
                date.year == now.year &&
                date.month == now.month) {
              thisMonth++;
            }
            if (data['isScheduled'] == true) scheduled++;
            if (data['isAutomated'] == true) automated++;
          }

          return ReportSummary(
            totalReports: total,
            thisMonthReports: thisMonth,
            scheduledReports: scheduled,
            automatedReports: automated,
          );
        })
        .handleError((e) {
          // Silenced as requested
          return ReportSummary(
            totalReports: 0,
            thisMonthReports: 0,
            scheduledReports: 0,
            automatedReports: 0,
          );
        });
  }

  Future<void> saveReport(GeneratedReport report) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final data = report.toMap();
    data['companyId'] = uid;
    data['createdAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users/$uid/reports').doc(report.id).set(data);
  }

  Future<List<GeneratedReport>> loadReports() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final path = 'users/$uid/reports';
      final snapshot = await _firestore
          .collection(path)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GeneratedReport.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading reports: $e');
      return [];
    }
  }
}
