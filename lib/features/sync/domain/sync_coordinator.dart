import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../../auth/domain/models/auth_session.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../data/mappers/sync_entity_firestore_mapper.dart';
import 'models/sync_entity.dart';
import 'repositories/cloud_data_repository.dart';
import 'repositories/sync_local_repository.dart';

typedef SyncApplyCallback = Future<void> Function(List<SyncEntity> entities);

class SyncCoordinator {
  SyncCoordinator({
    required this.authRepository,
    required this.localRepository,
    required this.cloudRepository,
    this.onRemoteChanges,
  });

  final AuthRepository authRepository;
  final SyncLocalRepository localRepository;
  final CloudDataRepository cloudRepository;
  final SyncApplyCallback? onRemoteChanges;
  final changes = StreamController<SyncState>.broadcast();
  StreamSubscription<AuthSession>? _authSubscription;
  Future<void>? _active;
  bool _rerun = false;
  SyncState? state;
  AuthSession _session = const AuthUnavailable();
  bool _disposed = false;
  bool _accountDeletionInProgress = false;
  SyncStatus status = SyncStatus.localOnly;

  Future<void> initialize() async {
    state = await localRepository.initialize();
    _emit();
    _authSubscription ??= authRepository.authStateChanges().listen((session) {
      _session = session;
      unawaited(_onAuthChangedSafely());
    });
  }

  Future<void> _onAuthChangedSafely() async {
    if (_disposed) return;
    try {
      await _onAuthChanged();
    } catch (_) {
      // Local account-state reads are optional to app startup and disposal.
    }
  }

  Future<void> _onAuthChanged() async {
    await _refreshState();
    if (_session case AuthSignedIn(user: final user)) {
      if (state?.linkedUid == null) {
        status = SyncStatus.readyToLink;
        _emit();
      } else if (state!.linkedUid != user.uid) {
        status = SyncStatus.accountMismatch;
        _emit();
      } else {
        unawaited(syncNow());
      }
    }
  }

  Future<void> activate(String uid) async {
    if (_currentUid != uid) throw StateError('Account changed before linking.');
    await _enqueueRun(() async {
      final current = await localRepository.getState();
      if (current.linkedUid != null && current.linkedUid != uid) {
        await localRepository.setError(
          'accountMismatch',
          DateTime.now().toUtc(),
        );
        return;
      }
      await _syncDataset(uid, linkUid: current.linkedUid == null ? uid : null);
    });
  }

  Future<void> syncNow() async => _enqueueRun(() async {
    final current = await localRepository.getState();
    final uid = _currentUid;
    if (uid == null || current.linkedUid == null) return;
    if (uid != current.linkedUid) {
      await localRepository.setError('accountMismatch', DateTime.now().toUtc());
      await _refreshState();
      return;
    }
    await _syncDataset(uid);
  });

  Future<T> runAccountDeletion<T>(
    String uid,
    Future<T> Function() action,
  ) async {
    if (_accountDeletionInProgress) {
      throw StateError('Account deletion is already in progress.');
    }
    _accountDeletionInProgress = true;
    try {
      final active = _active;
      if (active != null) await active;
      if (_currentUid != uid) {
        throw StateError('The signed-in account changed.');
      }
      return await action();
    } finally {
      _accountDeletionInProgress = false;
    }
  }

  Future<void> _syncDataset(String uid, {String? linkUid}) async {
    if (_currentUid != uid) return;
    final now = DateTime.now().toUtc();
    await localRepository.setAttemptStarted(now);
    await _refreshState(statusOverride: SyncStatus.syncing);
    try {
      if (_currentUid != uid) return;
      final cloud = await cloudRepository.fetchAccountDataset(uid);
      if (_currentUid != uid) return;
      if (cloud.invalidDocumentCount > 0) {
        throw const SyncDocumentException(
          SyncFailureCode.invalidRemoteDocument,
          'Cloud dataset contains invalid documents.',
        );
      }
      final local = await localRepository.getSnapshot();
      final pending = await localRepository.getPendingOperations(limit: 2000);
      final pendingByKey = {
        for (final op in pending) _key(op.type, op.entityKey): op,
      };
      final syncState = await localRepository.getState();
      final localByKey = {
        for (final entity in local) _key(entity.type, entity.id): entity,
      };
      final cloudByKey = {
        for (final entity in cloud.entities)
          _key(entity.type, entity.id): entity,
      };
      final remoteWinners = <SyncEntity>[];
      final localWinners = <SyncEntity>[];
      for (final entry in cloudByKey.entries) {
        final pendingOperation = pendingByKey[entry.key];
        final localSnapshot = localByKey[entry.key];
        final localEntity = pendingOperation?.operation == SyncOperation.delete
            ? SyncEntity(
                type: pendingOperation!.type,
                id: pendingOperation.entityKey,
                updatedAtUtc: pendingOperation.changedAtUtc,
                deletedAtUtc: pendingOperation.changedAtUtc,
                sourceDeviceId: syncState.deviceId,
                payload: null,
                isDeleted: true,
              )
            : localSnapshot;
        if (localEntity == null) {
          remoteWinners.add(entry.value);
        } else if (_compare(entry.value, localEntity) > 0) {
          remoteWinners.add(entry.value);
        } else if (_compare(localEntity, entry.value) > 0) {
          localWinners.add(localEntity);
        }
      }
      for (final entry in localByKey.entries) {
        if (!cloudByKey.containsKey(entry.key)) localWinners.add(entry.value);
      }
      if (_currentUid != uid) return;
      final appliedRemote = await localRepository.applyMerge(
        remoteWinners: remoteWinners,
        localWinners: localWinners,
        nowUtc: DateTime.now().toUtc(),
        linkedUid: linkUid,
        markInitialSyncComplete: linkUid != null,
      );
      if (appliedRemote.isNotEmpty) await onRemoteChanges?.call(appliedRemote);
      if (_currentUid != uid) return;
      await _flush(uid);
      if (_currentUid != uid) return;
      await cloudRepository.updateUserSyncMetadata(uid, DateTime.now().toUtc());
      await localRepository.markSuccessfulSync(DateTime.now().toUtc());
      await _refreshState();
    } catch (error) {
      final code = _errorCode(error);
      await localRepository.setError(code, DateTime.now().toUtc());
      await _refreshState(statusOverride: SyncStatus.error);
    }
  }

  Future<void> _flush(String uid) async {
    final state = await localRepository.getState();
    if (_currentUid != uid || state.linkedUid != uid) return;
    final pending = await localRepository.getPendingOperations();
    if (pending.isEmpty) return;
    final entities = <SyncEntity>[];
    final operationsToAcknowledge = <SyncOutboxOperation>[];
    for (final operation in pending) {
      if (_currentUid != uid) return;
      final entity = operation.operation == SyncOperation.delete
          ? SyncEntity(
              type: operation.type,
              id: operation.entityKey,
              updatedAtUtc: operation.changedAtUtc,
              deletedAtUtc: operation.changedAtUtc,
              sourceDeviceId: state.deviceId,
              payload: null,
              isDeleted: true,
            )
          : await localRepository.getEntity(
              operation.type,
              operation.entityKey,
              state.deviceId,
            );
      if (entity != null) {
        entities.add(entity);
        operationsToAcknowledge.add(operation);
      }
    }
    if (entities.isEmpty || _currentUid != uid) return;
    try {
      await cloudRepository.writeEntities(uid, entities);
      if (_currentUid != uid) return;
      for (final operation in operationsToAcknowledge) {
        await localRepository.acknowledge(operation);
      }
    } catch (error) {
      final code = _errorCode(error);
      for (final operation in operationsToAcknowledge) {
        await localRepository.recordFailure(operation, code);
      }
      rethrow;
    }
  }

  Future<void> _enqueueRun(Future<void> Function() action) async {
    if (_accountDeletionInProgress) return;
    if (_active != null) {
      _rerun = true;
      await _active;
      return;
    }
    _active = action();
    try {
      await _active;
    } finally {
      _active = null;
      if (_rerun && !_disposed) {
        _rerun = false;
        unawaited(syncNow());
      }
    }
  }

  Future<void> onAppResumed() => syncNow();

  Future<void> onLocalDataChanged() => syncNow();

  String? get _currentUid =>
      _session is AuthSignedIn ? (_session as AuthSignedIn).user.uid : null;

  Future<void> _refreshState({SyncStatus? statusOverride}) async {
    if (_disposed) return;
    state = await localRepository.getState();
    status = statusOverride ?? _statusForState();
    _emit(statusOverride: statusOverride);
  }

  SyncStatus _statusForState() {
    final currentUid = _currentUid;
    if (_session is AuthUnavailable) return SyncStatus.unavailable;
    if (state?.linkedUid != null &&
        currentUid != null &&
        state!.linkedUid != currentUid) {
      return SyncStatus.accountMismatch;
    }
    if (state?.linkedUid == null) {
      return currentUid == null ? SyncStatus.localOnly : SyncStatus.readyToLink;
    }
    if (state!.lastErrorCode != null) return SyncStatus.error;
    return state!.pendingCount == 0 ? SyncStatus.synced : SyncStatus.pending;
  }

  void _emit({SyncStatus? statusOverride}) {
    if (_disposed || state == null) return;
    if (statusOverride != null) status = statusOverride;
    changes.add(state!);
  }

  String _key(SyncEntityType type, String id) => '${type.storageValue}:$id';

  int _compare(SyncEntity left, SyncEntity right) {
    final time = left.updatedAtUtc.compareTo(right.updatedAtUtc);
    if (time != 0) return time;
    if (left.isDeleted != right.isDeleted) return left.isDeleted ? 1 : -1;
    return left.sourceDeviceId.compareTo(right.sourceDeviceId);
  }

  String _errorCode(Object error) {
    if (error case SyncDocumentException(failureCode: final code)) {
      return code.name;
    }
    if (error case FirebaseException(code: final code)) {
      return switch (code) {
        'permission-denied' || 'unauthenticated' => 'permissionDenied',
        'resource-exhausted' => 'quotaExceeded',
        'unavailable' || 'network-request-failed' => 'networkUnavailable',
        _ => 'syncUnavailable',
      };
    }
    return 'syncUnavailable';
  }

  Future<void> dispose() async {
    _disposed = true;
    await _authSubscription?.cancel();
    await changes.close();
  }
}
