enum SyncEntityType {
  routineDefinition,
  routineStepDefinition,
  routineRecord,
  routineStepRecord,
  dailyReflection,
  routineContent,
  routineAttachment,
}

extension SyncEntityTypeStorage on SyncEntityType {
  String get storageValue => switch (this) {
    SyncEntityType.routineDefinition => 'routineDefinition',
    SyncEntityType.routineStepDefinition => 'routineStepDefinition',
    SyncEntityType.routineRecord => 'routineRecord',
    SyncEntityType.routineStepRecord => 'routineStepRecord',
    SyncEntityType.dailyReflection => 'dailyReflection',
    SyncEntityType.routineContent => 'routineContent',
    SyncEntityType.routineAttachment => 'routineAttachment',
  };

  static SyncEntityType? fromStorage(String value) => switch (value) {
    'routineDefinition' => SyncEntityType.routineDefinition,
    'routineStepDefinition' => SyncEntityType.routineStepDefinition,
    'routineRecord' => SyncEntityType.routineRecord,
    'routineStepRecord' => SyncEntityType.routineStepRecord,
    'dailyReflection' => SyncEntityType.dailyReflection,
    'routineContent' => SyncEntityType.routineContent,
    'routineAttachment' => SyncEntityType.routineAttachment,
    _ => null,
  };
}

class SyncEntity {
  const SyncEntity({
    required this.type,
    required this.id,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
    required this.payload,
    this.isDeleted = false,
    this.deletedAtUtc,
  });

  final SyncEntityType type;
  final String id;
  final DateTime updatedAtUtc;
  final String sourceDeviceId;
  final Object? payload;
  final bool isDeleted;
  final DateTime? deletedAtUtc;
}

class SyncOutboxOperation {
  const SyncOutboxOperation({
    required this.type,
    required this.entityKey,
    required this.operation,
    required this.changedAtUtc,
    required this.attemptCount,
    this.lastErrorCode,
  });

  final SyncEntityType type;
  final String entityKey;
  final SyncOperation operation;
  final DateTime changedAtUtc;
  final int attemptCount;
  final String? lastErrorCode;
}

enum SyncOperation { upsert, delete }

enum SyncStatus {
  localOnly,
  readyToLink,
  syncing,
  synced,
  pending,
  offline,
  accountMismatch,
  unavailable,
  error,
}

enum SyncFailureCode {
  networkUnavailable,
  permissionDenied,
  quotaExceeded,
  invalidRemoteDocument,
  unsupportedSchema,
  accountMismatch,
  serviceUnavailable,
  unknown,
}

class SyncState {
  const SyncState({
    required this.deviceId,
    required this.linkedUid,
    required this.initialSyncCompleted,
    required this.pendingCount,
    this.lastAttemptAtUtc,
    this.lastSuccessfulSyncAtUtc,
    this.lastErrorCode,
  });

  final String deviceId;
  final String? linkedUid;
  final bool initialSyncCompleted;
  final int pendingCount;
  final DateTime? lastAttemptAtUtc;
  final DateTime? lastSuccessfulSyncAtUtc;
  final String? lastErrorCode;
}
