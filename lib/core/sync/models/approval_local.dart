import 'package:hive/hive.dart';

part 'approval_local.g.dart';

@HiveType(typeId: 6) // Ensure typeId doesn't conflict with existing ones
class ApprovalLocal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String assetId;

  @HiveField(2)
  final String requestedBy;

  @HiveField(3)
  final String actionType; // 'dispose' or 'transfer'

  @HiveField(4)
  final String status; // 'pending', 'approved', 'rejected'

  @HiveField(5)
  final String? approvedBy;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final Map<String, dynamic>? details; // e.g transfer destination

  ApprovalLocal({
    required this.id,
    required this.assetId,
    required this.requestedBy,
    required this.actionType,
    required this.status,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.details,
  });

  factory ApprovalLocal.fromJson(Map<String, dynamic> json) {
    return ApprovalLocal(
      id: json['id'],
      assetId: json['asset_id'],
      requestedBy: json['requested_by'],
      actionType: json['action_type'],
      status: json['status'],
      approvedBy: json['approved_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'requested_by': requestedBy,
      'action_type': actionType,
      'status': status,
      'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'details': details,
    };
  }
}
