import 'package:hive/hive.dart';

part 'company_user_local.g.dart';

/// Locally cached user profile with company membership and role.
@HiveType(typeId: 12)
class CompanyUserLocal extends HiveObject {
  CompanyUserLocal({
    required this.uid,
    required this.companyId,
    required this.role,
    required this.name,
    required this.email,
    required this.deviceId,
  });

  @HiveField(0)
  String uid;

  @HiveField(1)
  String companyId;

  /// 'admin' | 'manager' | 'viewer'
  @HiveField(2)
  String role;

  @HiveField(3)
  String name;

  @HiveField(4)
  String email;

  /// Device identifier (stable per install) used in sync operations.
  @HiveField(5)
  String deviceId;

  bool get isAdmin => role == 'admin';
  bool get canWrite => role == 'admin' || role == 'manager';
  bool get isViewer => role == 'viewer';
}
