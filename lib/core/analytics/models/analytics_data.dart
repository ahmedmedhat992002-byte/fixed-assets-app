class AnalyticsData {
  final double totalRegisteredValue;
  final double currentValue;
  final double projectedIncrease;
  final int totalAssetsCount;

  // 6-months trend data (value on registration, current value, projected increase)
  // Maps "MMM" (e.g., "Jan") to a list of three values.
  final Map<String, List<double>> sixMonthTrend;

  // Analysis by category. Maps category name to [registeredValue, currentValue, projectedIncrease]
  final Map<String, List<double>> analysisByCategory;

  // Analysis by status. Maps status name to count
  final Map<String, int> analysisByStatus;

  // Analysis by category count. Maps category name to count
  final Map<String, int> analysisByCategoryCount;

  // Analysis by warehouse. Maps warehouse name to a map of category counts.
  // e.g., {'Cairo': {'Machinery': 5, 'Furniture': 2}}
  final Map<String, Map<String, int>> analysisByWarehouse;

  final int industriesCount;
  final String highestValueAsset;
  final String lowestValueAsset;

  AnalyticsData({
    required this.totalRegisteredValue,
    required this.currentValue,
    required this.projectedIncrease,
    required this.totalAssetsCount,
    required this.sixMonthTrend,
    required this.analysisByCategory,
    required this.analysisByStatus,
    required this.analysisByCategoryCount,
    required this.analysisByWarehouse,
    required this.industriesCount,
    required this.highestValueAsset,
    required this.lowestValueAsset,
  });

  factory AnalyticsData.empty() {
    return AnalyticsData(
      totalRegisteredValue: 0.0,
      currentValue: 0.0,
      projectedIncrease: 0.0,
      totalAssetsCount: 0,
      sixMonthTrend: {},
      analysisByCategory: {},
      analysisByStatus: {},
      analysisByCategoryCount: {},
      analysisByWarehouse: {},
      industriesCount: 0,
      highestValueAsset: '-',
      lowestValueAsset: '-',
    );
  }
}

class MaintenanceData {
  // Maps month "MMM" to [emergencyCost, scheduledCost]
  final Map<String, List<double>> costsByMonth;

  MaintenanceData({required this.costsByMonth});

  factory MaintenanceData.empty() {
    return MaintenanceData(costsByMonth: {});
  }
}
