import 'package:hive/hive.dart';

part 'sync_operation.g.dart';

/// The type of CRUD operation.
@HiveType(typeId: 10)
class SyncOperation extends HiveObject {
  SyncOperation({
    required this.operationId,
    required this.type,
    required this.collection,
    required this.documentId,
    required this.payload,
    required this.baseVersion,
    required this.deviceId,
    required this.timestamp,
    this.synced = false,
    this.retryCount = 0,
  });

  /// Unique identifier (UUID v4) for idempotency checks.
  @HiveField(0)
  String operationId;

  /// 'create' | 'update' | 'delete'
  @HiveField(1)
  String type;

  /// Firestore sub-collection name, e.g. 'assets' | 'users'.
  @HiveField(2)
  String collection;

  /// The target document ID.
  @HiveField(3)
  String documentId;

  /// The full payload to write (or partial for update).
  @HiveField(4)
  Map<String, dynamic> payload;

  /// The version the client *thinks* the document is on.
  /// Use 0 for create operations.
  @HiveField(5)
  int baseVersion;

  /// Device ID used for audit trail and conflict tracking.
  @HiveField(6)
  String deviceId;

  /// Client-side Unix epoch milliseconds.
  @HiveField(7)
  int timestamp;

  /// True once the Cloud Function has confirmed this operation.
  @HiveField(8)
  bool synced;

  /// How many times we've attempted to sync this op.
  @HiveField(9)
  int retryCount;

  Map<String, dynamic> toMap() => {
    'operationId': operationId,
    'type': type,
    'collection': collection,
    'documentId': documentId,
    'payload': payload,
    'baseVersion': baseVersion,
    'deviceId': deviceId,
    'timestamp': timestamp,
  };
}
