import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'models/analytics_data.dart';
import '../utils/data_utils.dart';

class AnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate Date Range based on Period Filter
  (DateTime start, DateTime end) _getDateRanges(String period) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (period) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'All':
      default:
        start = DateTime(2000);
    }
    return (start, end);
  }

  /// Generate a list of the last 6 months in 'MMM' format (e.g., ['Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'])
  List<String> _getLast6Months() {
    final now = DateTime.now();
    final formatter = DateFormat('MMM');
    final months = <String>[];
    for (int i = 5; i >= 0; i--) {
      months.add(formatter.format(DateTime(now.year, now.month - i, 1)));
    }
    return months;
  }

  /// Streams aggregated AnalyticsData from the user's `assets` collection.
  Stream<AnalyticsData> getAnalyticsDataStream(
    String uid, {
    String period = 'All',
  }) {
    if (uid.isEmpty) return Stream.value(AnalyticsData.empty());

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('assets')
        .snapshots()
        .map((snapshot) {
          final ranges = _getDateRanges(period);
          final startTs = Timestamp.fromDate(ranges.$1);
          final endTs = Timestamp.fromDate(ranges.$2);

          double totalRegValue = 0.0;
          double currentVal = 0.0;
          double projectedInc = 0.0;
          int count = snapshot.docs.length;

          // Initialize structures
          final last6MonthsStr = _getLast6Months();
          final Map<String, List<double>> trend = {
            for (var m in last6MonthsStr) m: [0.0, 0.0, 0.0],
          };

          final Map<String, List<double>> byCategory = {};
          final Map<String, int> byCategoryCount = {};
          final Map<String, int> byStatus = {};
          final Set<String> industries = {};
          final Map<String, Map<String, int>> byWarehouse = {};

          String highestAsset = '-';
          double maxVal = -1.0;
          String lowestAsset = '-';
          double minVal = double.infinity;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final name = DataUtils.asString(data['name'], 'Unknown');
            final regVal = DataUtils.asDouble(data['purchasePrice']);
            // Fallback: if currentValue is 0 or missing, use purchasePrice
            double cVal = DataUtils.asDouble(data['currentValue']);
            if (cVal == 0 && regVal > 0) {
              cVal = regVal;
            }
            final pInc = DataUtils.asDouble(data['projectedGrowth']);

            totalRegValue += regVal;
            currentVal += cVal;
            projectedInc += pInc;

            // Track highest/lowest based on currentValue
            if (cVal > maxVal) {
              maxVal = cVal;
              highestAsset = name;
            }
            if (cVal < minVal && cVal > 0) {
              minVal = cVal;
              lowestAsset = name;
            }

            final dateSource =
                data['purchaseDateMs'] ??
                data['createdAt'] ??
                data['createdAtMs'] ??
                data['updatedAtMs'];

            final ts = DataUtils.asTimestamp(dateSource);
            if (ts != null) {
              if (ts.compareTo(startTs) < 0 || ts.compareTo(endTs) > 0) {
                continue; // Skip if outside period
              }
            } else if (period != 'All') {
              continue; // Skip if no date and filtering by period
            }

            DateTime trendDate = DataUtils.asDateTime(
              dateSource,
              DateTime.now(),
            );

            final monthStr = DateFormat('MMM').format(trendDate);
            if (trend.containsKey(monthStr)) {
              trend[monthStr]![0] += regVal;
              trend[monthStr]![1] += cVal;
              trend[monthStr]![2] += pInc;
            }

            // Category grouping
            final categoryRaw = DataUtils.asString(data['category']).trim();
            final displayCat = categoryRaw.isEmpty
                ? 'Uncategorized'
                : categoryRaw[0].toUpperCase() + categoryRaw.substring(1);

            if (!byCategory.containsKey(displayCat)) {
              byCategory[displayCat] = [0.0, 0.0, 0.0];
            }
            byCategory[displayCat]![0] += regVal;
            byCategory[displayCat]![1] += cVal;
            byCategory[displayCat]![2] += pInc;
            byCategoryCount[displayCat] =
                (byCategoryCount[displayCat] ?? 0) + 1;

            // Warehouse (Location) grouping
            final location = DataUtils.asString(data['location']).trim();
            if (location.isNotEmpty) {
              // Normalize location name (e.g., "cairo" -> "Cairo")
              final displayLoc =
                  location[0].toUpperCase() +
                  location.substring(1).toLowerCase();

              if (!byWarehouse.containsKey(displayLoc)) {
                byWarehouse[displayLoc] = {};
              }

              // We use normalized category for warehouse keys (e.g., "Machinery")
              byWarehouse[displayLoc]![displayCat] =
                  (byWarehouse[displayLoc]![displayCat] ?? 0) + 1;
            }

            // Status grouping
            final status = DataUtils.asString(data['status']).trim();
            final displayStatus = status.isEmpty
                ? 'Active'
                : status[0].toUpperCase() + status.substring(1).toLowerCase();
            byStatus[displayStatus] = (byStatus[displayStatus] ?? 0) + 1;

            // Industry (department) grouping
            final dept = DataUtils.asString(data['department']).trim();
            if (dept.isNotEmpty) {
              industries.add(dept);
            }
          }

          return AnalyticsData(
            totalRegisteredValue: totalRegValue,
            currentValue: currentVal,
            projectedIncrease: projectedInc,
            totalAssetsCount: count,
            sixMonthTrend: trend,
            analysisByCategory: byCategory,
            analysisByStatus: byStatus,
            analysisByCategoryCount: byCategoryCount,
            analysisByWarehouse: byWarehouse,
            industriesCount: industries.length,
            highestValueAsset: highestAsset,
            lowestValueAsset: lowestAsset,
          );
        })
        .handleError((error) {
          debugPrint(
            'AnalyticsService Error in getAnalyticsDataStream: $error',
          );
          return AnalyticsData.empty();
        });
  }

  /// Streams aggregated MaintenanceData from the user's `maintenance` collection.
  Stream<MaintenanceData> getMaintenanceDataStream(String uid) {
    if (uid.isEmpty) return Stream.value(MaintenanceData.empty());

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('maintenance')
        .snapshots()
        .map((snapshot) {
          final last6MonthsStr = _getLast6Months();
          final Map<String, List<double>> costs = {
            for (var m in last6MonthsStr)
              m: [0.0, 0.0], // [emergency, scheduled]
          };

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final cost = DataUtils.asDouble(data['cost']);
            final type = DataUtils.asString(
              data['type'],
              'scheduled',
            ).toLowerCase();

            DateTime date = DataUtils.asDateTime(data['date'], DateTime.now());

            final monthStr = DateFormat('MMM').format(date);
            if (costs.containsKey(monthStr)) {
              if (type == 'emergency') {
                costs[monthStr]![0] += cost;
              } else {
                costs[monthStr]![1] += cost;
              }
            }
          }

          return MaintenanceData(costsByMonth: costs);
        })
        .handleError((error) {
          debugPrint(
            'AnalyticsService Error in getMaintenanceDataStream: $error',
          );
          return MaintenanceData.empty();
        });
  }
}
