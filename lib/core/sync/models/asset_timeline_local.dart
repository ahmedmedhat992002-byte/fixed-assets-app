import 'package:hive/hive.dart';

part 'asset_timeline_local.g.dart';

@HiveType(typeId: 7) // Ensure typeId doesn't conflict with existing ones
class AssetTimelineLocal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String assetId;

  @HiveField(2)
  final String action; // e.g., 'created', 'transferred', 'disposed', 'maintenance'

  @HiveField(3)
  final String? userId;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final Map<String, dynamic>? details;

  AssetTimelineLocal({
    required this.id,
    required this.assetId,
    required this.action,
    this.userId,
    required this.timestamp,
    this.details,
  });

  factory AssetTimelineLocal.fromJson(Map<String, dynamic> json) {
    return AssetTimelineLocal(
      id: json['id'],
      assetId: json['asset_id'],
      action: json['action'],
      userId: json['user_id'],
      timestamp: DateTime.parse(json['timestamp']),
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'action': action,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}
