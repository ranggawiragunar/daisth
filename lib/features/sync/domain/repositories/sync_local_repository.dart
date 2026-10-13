import '../models/sync_entity.dart';

abstract interface class SyncLocalRepository {
  Future<SyncState> initialize();
  Future<SyncState> getState();
  Future<List<SyncEntity>> getSnapshot();
  Future<SyncEntity?> getEntity(
    SyncEntityType type,
    String entityKey,
    String deviceId,
  );
  Future<List<SyncOutboxOperation>> getPendingOperations({int limit = 400});
  Future<void> setAttemptStarted(DateTime nowUtc);
  Future<List<SyncEntity>> applyMerge({
    required List<SyncEntity> remoteWinners,
    required List<SyncEntity> localWinners,
    required DateTime nowUtc,
    String? linkedUid,
    bool markInitialSyncComplete = false,
  });
  Future<void> acknowledge(SyncOutboxOperation operation);
  Future<void> recordFailure(SyncOutboxOperation operation, String errorCode);
  Future<void> markSuccessfulSync(DateTime nowUtc);
  Future<void> setError(String? errorCode, DateTime nowUtc);
  Future<void> clearLinkForDeletedAccount(String uid);
}
