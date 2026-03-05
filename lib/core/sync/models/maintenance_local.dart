import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../utils/data_utils.dart';

part 'maintenance_local.g.dart';

@HiveType(typeId: 13)
class MaintenanceLocal extends HiveObject {
  MaintenanceLocal({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.dateMs,
    required this.type,
    required this.cost,
    this.technician,
    this.vendor,
    this.notes,
    required this.status, // 'scheduled', 'in_progress', 'completed'
    required this.updatedAtMs,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String assetId;

  @HiveField(2)
  String assetName;

  @HiveField(3)
  int dateMs;

  /// 'preventive', 'corrective', 'emergency', 'scheduled'
  @HiveField(4)
  String type;

  @HiveField(5)
  double cost;

  @HiveField(6)
  String? technician;

  @HiveField(7)
  String? vendor;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  String status;

  @HiveField(10)
  int updatedAtMs;

  Map<String, dynamic> toMap() => {
    'id': id,
    'assetId': assetId,
    'assetName': assetName,
    'dateMs': dateMs,
    'type': type,
    'cost': cost,
    if (technician != null) 'technician': technician,
    if (vendor != null) 'vendor': vendor,
    if (notes != null) 'notes': notes,
    'status': status,
    'updatedAtMs': updatedAtMs,
  };

  factory MaintenanceLocal.fromMap(String id, Map<String, dynamic> map) {
    return MaintenanceLocal(
      id: id,
      assetId: DataUtils.asString(map['assetId']),
      assetName: DataUtils.asString(map['assetName']),
      dateMs: DataUtils.asInt(
        map['dateMs'] ??
            (map['date'] is Timestamp
                ? (map['date'] as Timestamp).millisecondsSinceEpoch
                : map['date']),
      ),
      type: DataUtils.asString(map['type'], 'other'),
      cost: DataUtils.asDouble(map['cost']),
      technician: map['technician'] as String?,
      vendor: map['vendor'] as String?,
      notes: map['notes'] as String?,
      status: DataUtils.asString(map['status'], 'completed'),
      updatedAtMs: DataUtils.asInt(map['updatedAtMs']),
    );
  }
}
