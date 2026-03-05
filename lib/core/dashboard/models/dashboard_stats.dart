class DashboardStats {
  final double totalValue;
  final double totalDepreciation;
  final double netValue;
  final int assetsInMaintenance;
  final int newAssetsThisPeriod;
  final int disposedAssets;
  final double totalMaintenanceCost;

  DashboardStats({
    required this.totalValue,
    required this.totalDepreciation,
    required this.netValue,
    this.assetsInMaintenance = 0,
    this.newAssetsThisPeriod = 0,
    this.disposedAssets = 0,
    this.totalMaintenanceCost = 0.0,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalValue: 0.0,
      totalDepreciation: 0.0,
      netValue: 0.0,
    );
  }
}
