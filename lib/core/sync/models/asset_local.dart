import 'dart:math' as math;
import 'package:hive/hive.dart';
import '../../utils/data_utils.dart';

part 'asset_local.g.dart';

/// Local (offline) representation of a fixed asset stored in Hive.
/// Version is sourced from Firestore and used for conflict detection.
@HiveType(typeId: 11)
class AssetLocal extends HiveObject {
  AssetLocal({
    required this.id,
    required this.companyId,
    required this.name,
    required this.category,
    required this.status,
    required this.purchasePrice,
    required this.currentValue,
    required this.depreciationMethod,
    required this.version,
    required this.updatedAtMs,
    this.location,
    this.assignedTo,
    this.department,
    this.vendor,
    this.description,
    this.usefulLife,
    this.salvageValue,
    this.purchaseDateMs,
    this.warrantyExpiryMs,
    this.latitude,
    this.longitude,
    this.lastScannedAtMs,
    this.isDirty = false,
  });

  factory AssetLocal.fromMap(Map<String, dynamic> data, String id, String uid) {
    return AssetLocal(
      id: id,
      companyId: DataUtils.asString(data['companyId'], uid),
      name: DataUtils.asString(data['name'], 'Unknown Asset'),
      category: DataUtils.asString(data['category'], 'Uncategorized'),
      status: DataUtils.asString(data['status'], 'active'),
      purchasePrice: DataUtils.asDouble(data['purchasePrice']),
      currentValue: DataUtils.asDouble(data['currentValue']),
      depreciationMethod: DataUtils.asString(
        data['depreciationMethod'],
        'straight_line',
      ),
      version: DataUtils.asInt(data['version'], 1),
      updatedAtMs: DataUtils.asInt(
        data['updatedAtMs'],
        DateTime.now().millisecondsSinceEpoch,
      ),
      location: DataUtils.asStringNullable(data['location']),
      assignedTo: DataUtils.asStringNullable(data['assignedTo']),
      department: DataUtils.asStringNullable(data['department']),
      vendor: DataUtils.asStringNullable(data['vendor']),
      description: DataUtils.asStringNullable(data['description']),
      usefulLife: DataUtils.asIntNullable(data['usefulLife']),
      salvageValue: DataUtils.asDoubleNullable(data['salvageValue']),
      purchaseDateMs: DataUtils.asIntNullable(data['purchaseDateMs']),
      warrantyExpiryMs: DataUtils.asIntNullable(data['warrantyExpiryMs']),
      latitude: DataUtils.asDoubleNullable(data['latitude']),
      longitude: DataUtils.asDoubleNullable(data['longitude']),
      lastScannedAtMs: DataUtils.asIntNullable(data['lastScannedAtMs']),
      isDirty: false,
    );
  }

  @HiveField(0)
  String id;

  @HiveField(1)
  String companyId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String category;

  /// 'active' | 'inactive' | 'maintenance' | 'disposed'
  @HiveField(4)
  String status;

  @HiveField(5)
  String? location;

  /// User ID of the assigned person.
  @HiveField(6)
  String? assignedTo;

  @HiveField(18)
  String? department;

  @HiveField(19)
  String? vendor;

  @HiveField(7)
  double purchasePrice;

  @HiveField(8)
  double currentValue;

  @HiveField(9)
  String depreciationMethod;

  @HiveField(10)
  String? description;

  /// Useful life in years.
  @HiveField(11)
  int? usefulLife;

  @HiveField(12)
  double? salvageValue;

  @HiveField(13)
  int? purchaseDateMs;

  /// Monotonic version sourced from Firestore — used in conflict detection.
  @HiveField(14)
  int version;

  /// True when local edits are not yet flushed to Firestore.
  @HiveField(15)
  bool isDirty;

  /// Last modification timestamp in epoch milliseconds.
  @HiveField(16)
  int updatedAtMs;

  @HiveField(17)
  int? warrantyExpiryMs;

  @HiveField(20)
  double? latitude;

  @HiveField(21)
  double? longitude;

  @HiveField(22)
  int? lastScannedAtMs;

  Map<String, dynamic> toMap() => {
    'id': id,
    'companyId': companyId,
    'name': name,
    'category': category,
    'status': status,
    if (location != null) 'location': location,
    if (assignedTo != null) 'assignedTo': assignedTo,
    if (department != null) 'department': department,
    if (vendor != null) 'vendor': vendor,
    'purchasePrice': purchasePrice,
    'currentValue': currentValue,
    'depreciationMethod': depreciationMethod,
    if (description != null) 'description': description,
    if (usefulLife != null) 'usefulLife': usefulLife,
    if (salvageValue != null) 'salvageValue': salvageValue,
    if (purchaseDateMs != null) 'purchaseDateMs': purchaseDateMs,
    if (warrantyExpiryMs != null) 'warrantyExpiryMs': warrantyExpiryMs,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (lastScannedAtMs != null) 'lastScannedAtMs': lastScannedAtMs,
    'version': version,
    'updatedAtMs': updatedAtMs,
  };

  AssetLocal copyWith({
    String? name,
    String? category,
    String? status,
    String? location,
    String? assignedTo,
    String? department,
    String? vendor,
    double? purchasePrice,
    double? currentValue,
    String? depreciationMethod,
    String? description,
    int? usefulLife,
    double? salvageValue,
    int? purchaseDateMs,
    int? warrantyExpiryMs,
    double? latitude,
    double? longitude,
    int? lastScannedAtMs,
    bool? isDirty,
    int? version,
  }) {
    return AssetLocal(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      location: location ?? this.location,
      assignedTo: assignedTo ?? this.assignedTo,
      department: department ?? this.department,
      vendor: vendor ?? this.vendor,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentValue: currentValue ?? this.currentValue,
      depreciationMethod: depreciationMethod ?? this.depreciationMethod,
      description: description ?? this.description,
      usefulLife: usefulLife ?? this.usefulLife,
      salvageValue: salvageValue ?? this.salvageValue,
      purchaseDateMs: purchaseDateMs ?? this.purchaseDateMs,
      warrantyExpiryMs: warrantyExpiryMs ?? this.warrantyExpiryMs,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastScannedAtMs: lastScannedAtMs ?? this.lastScannedAtMs,
      version: version ?? this.version,
      isDirty: isDirty ?? this.isDirty,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Calculates the estimated depreciation based on the purchase date, useful life,
  /// and depreciation method. Currently supports Straight-line depreciation.
  double getEstimatedDepreciation() {
    if (purchasePrice <= 0 ||
        usefulLife == null ||
        usefulLife! <= 0 ||
        purchaseDateMs == null) {
      return 0.0;
    }

    final purchaseDate = DateTime.fromMillisecondsSinceEpoch(purchaseDateMs!);
    final now = DateTime.now();
    final yearsOwned = now.difference(purchaseDate).inDays / 365.25;

    if (yearsOwned <= 0) return 0.0;

    double annualDepreciation = 0.0;
    final salvage = salvageValue ?? 0.0;

    // We assume straight-line if method is not specified or recognized
    // Formula: (Cost - Salvage) / Useful Life
    annualDepreciation = (purchasePrice - salvage) / usefulLife!;

    final totalDepreciation = annualDepreciation * yearsOwned;

    // Ensure it doesn't exceed the depresiable amount
    final maxDepreciation = math.max(0.0, purchasePrice - salvage);
    return totalDepreciation.clamp(0.0, maxDepreciation);
  }
}
