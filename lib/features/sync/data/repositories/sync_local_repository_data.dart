import '../../domain/models/sync_entity.dart';
import '../../domain/repositories/sync_local_repository.dart';
import '../services/sync_sqlite_service.dart';

class SyncLocalRepositoryData implements SyncLocalRepository {
  const SyncLocalRepositoryData(this.service);

  final SyncSqliteService service;

  @override
  Future<SyncState> initialize() => service.initialize();
  @override
  Future<SyncState> getState() => service.getState();
  @override
  Future<List<SyncEntity>> getSnapshot() => service.getSnapshot();
  @override
  Future<SyncEntity?> getEntity(
    SyncEntityType type,
    String entityKey,
    String deviceId,
  ) => service.getEntity(type, entityKey, deviceId);
  @override
  Future<List<SyncOutboxOperation>> getPendingOperations({int limit = 400}) =>
      service.getPending(limit: limit);
  @override
  Future<void> setAttemptStarted(DateTime nowUtc) => service.setAttempt(nowUtc);
  @override
  Future<List<SyncEntity>> applyMerge({
    required List<SyncEntity> remoteWinners,
    required List<SyncEntity> localWinners,
    required DateTime nowUtc,
    String? linkedUid,
    bool markInitialSyncComplete = false,
  }) => service.applyMerge(
    remoteWinners: remoteWinners,
    localWinners: localWinners,
    nowUtc: nowUtc,
    linkedUid: linkedUid,
    markInitialSyncComplete: markInitialSyncComplete,
  );
  @override
  Future<void> acknowledge(SyncOutboxOperation operation) =>
      service.removeOutbox(operation);
  @override
  Future<void> recordFailure(SyncOutboxOperation operation, String errorCode) =>
      service.updateOutboxFailure(operation, errorCode);
  @override
  Future<void> markSuccessfulSync(DateTime nowUtc) =>
      service.markSuccess(nowUtc);
  @override
  Future<void> setError(String? errorCode, DateTime nowUtc) =>
      service.setError(errorCode, nowUtc);
}
