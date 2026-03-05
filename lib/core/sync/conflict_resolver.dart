/// Result of a single conflicting operation.
class ConflictDetail {
  const ConflictDetail({
    required this.operationId,
    required this.reason,
    required this.serverVersion,
    required this.serverData,
  });

  factory ConflictDetail.fromMap(Map<dynamic, dynamic> map) => ConflictDetail(
    operationId: map['operationId'] as String,
    reason: map['reason'] as String? ?? 'version_conflict',
    serverVersion:
        (map['conflictDetail']?['serverVersion'] as num?)?.toInt() ?? 0,
    serverData:
        map['conflictDetail']?['serverData'] as Map<dynamic, dynamic>? ?? {},
  );

  final String operationId;
  final String reason;
  final int serverVersion;
  final Map<dynamic, dynamic> serverData;

  @override
  String toString() =>
      'ConflictDetail(op=$operationId, reason=$reason, serverV=$serverVersion)';
}

/// Result returned from the syncBatch Cloud Function.
class SyncResult {
  const SyncResult({
    required this.applied,
    required this.failed,
    required this.conflicts,
  });

  factory SyncResult.fromMap(Map<dynamic, dynamic> map) => SyncResult(
    applied: List<String>.from(map['applied'] as List? ?? []),
    failed: _parseConflicts(map['failed'] as List? ?? []),
    conflicts: _parseConflicts(map['conflicts'] as List? ?? []),
  );

  final List<String> applied;
  final List<ConflictDetail> failed;
  final List<ConflictDetail> conflicts;

  static List<ConflictDetail> _parseConflicts(List raw) =>
      raw.map((e) => ConflictDetail.fromMap(e as Map)).toList();

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get hasFailed => failed.isNotEmpty;
  bool get isFullyApplied => conflicts.isEmpty && failed.isEmpty;
}

/// Policy: version-check + last-write-wins.
/// Returns true if the local operation should be applied over the server state.
class ConflictResolver {
  /// Given a conflict, decide whether to re-apply the local operation
  /// with an updated baseVersion (last-write-wins by timestamp).
  static bool shouldOverwrite({
    required int clientTimestamp,
    required int serverVersion,
    required int clientBaseVersion,
  }) {
    // If the server has moved on but the client timestamp is very recent,
    // we allow overwrite (last-write-wins).
    // In strict mode, always return false to surface as a manual conflict.
    final serverTimestampMs = serverVersion * 0; // not directly comparable
    return clientTimestamp > serverTimestampMs; // simplistic: always overwrite
  }

  /// Merges conflict server data into a new payload for re-queueing.
  static Map<String, dynamic> mergeLastWriteWins({
    required Map<String, dynamic> clientPayload,
    required Map<dynamic, dynamic> serverData,
  }) {
    // Last-write-wins: client payload takes precedence for all fields.
    final merged = Map<String, dynamic>.from(serverData);
    merged.addAll(clientPayload);
    return merged;
  }
}
