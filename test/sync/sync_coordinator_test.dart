import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/auth/domain/models/auth_session.dart';
import 'package:daisth/features/auth/domain/models/auth_user.dart';
import 'package:daisth/features/auth/domain/repositories/auth_repository.dart';
import 'package:daisth/features/sync/domain/models/sync_entity.dart';
import 'package:daisth/features/sync/domain/repositories/cloud_data_repository.dart';
import 'package:daisth/features/sync/domain/repositories/sync_local_repository.dart';
import 'package:daisth/features/sync/domain/sync_coordinator.dart';

void main() {
  test('Google sign-in does not link until explicit activation', () async {
    final local = _MemorySyncLocalRepository();
    final cloud = _MemoryCloudRepository(() => local.state.linkedUid);
    final coordinator = SyncCoordinator(
      authRepository: _MemoryAuthRepository('user-a'),
      localRepository: local,
      cloudRepository: cloud,
    );
    addTearDown(coordinator.dispose);

    await coordinator.initialize();
    await Future<void>.delayed(Duration.zero);
    expect(local.state.linkedUid, isNull);
    expect(cloud.fetchCount, 0);

    await coordinator.activate('user-a');
    expect(cloud.linkAtFetch, isNull);
    expect(local.state.linkedUid, 'user-a');
    expect(local.state.initialSyncCompleted, isTrue);
  });

  test('a different signed-in UID performs no cloud operations', () async {
    final local = _MemorySyncLocalRepository(linkedUid: 'user-a');
    final cloud = _MemoryCloudRepository(() => local.state.linkedUid);
    final coordinator = SyncCoordinator(
      authRepository: _MemoryAuthRepository('user-b'),
      localRepository: local,
      cloudRepository: cloud,
    );
    addTearDown(coordinator.dispose);

    await coordinator.initialize();
    await Future<void>.delayed(Duration.zero);
    await coordinator.syncNow();

    expect(coordinator.status, SyncStatus.accountMismatch);
    expect(cloud.fetchCount, 0);
    expect(cloud.writeCount, 0);
    expect(local.state.linkedUid, 'user-a');
  });

  test(
    'account deletion lock blocks a new sync run until purge finishes',
    () async {
      final local = _MemorySyncLocalRepository(linkedUid: 'user-a');
      final cloud = _MemoryCloudRepository(() => local.state.linkedUid);
      final coordinator = SyncCoordinator(
        authRepository: _MemoryAuthRepository('user-a'),
        localRepository: local,
        cloudRepository: cloud,
      );
      addTearDown(coordinator.dispose);
      await coordinator.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final fetchesBeforeDelete = cloud.fetchCount;
      final entered = Completer<void>();
      final release = Completer<void>();

      final deletion = coordinator.runAccountDeletion('user-a', () async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      await coordinator.syncNow();
      expect(cloud.fetchCount, fetchesBeforeDelete);

      release.complete();
      await deletion;
    },
  );
}

class _MemoryAuthRepository implements AuthRepository {
  _MemoryAuthRepository(String uid)
    : _session = AuthSignedIn(AuthUser(uid: uid, email: '$uid@example.com'));
  final AuthSession _session;
  @override
  Stream<AuthSession> authStateChanges() => Stream.value(_session);
  @override
  Future<AuthSession> currentSession() async => _session;
  @override
  Future<AuthUser> signInWithGoogle() async => (_session as AuthSignedIn).user;
  @override
  Future<AuthUser> signInWithApple() async => (_session as AuthSignedIn).user;
  @override
  Future<void> signOut() async {}
  @override
  Future<AuthUser> reauthenticateWithGoogle() async =>
      (_session as AuthSignedIn).user;
  @override
  Future<AuthUser> reauthenticateWithApple() async =>
      (_session as AuthSignedIn).user;
  @override
  Future<void> revokeAppleAuthorizationToken() async {}
  @override
  Future<void> deleteCurrentUser() async {}
  @override
  Future<void> disconnectGoogle() async {}
  @override
  Future<void> retryAvailability() async {}
}

class _MemoryCloudRepository implements CloudDataRepository {
  _MemoryCloudRepository(this.readLinkedUid);
  final String? Function() readLinkedUid;
  int fetchCount = 0;
  int writeCount = 0;
  String? linkAtFetch;
  @override
  Future<CloudDataset> fetchAccountDataset(String uid) async {
    fetchCount++;
    linkAtFetch = readLinkedUid();
    return const CloudDataset(entities: []);
  }

  @override
  Future<void> writeEntities(String uid, List<SyncEntity> entities) async {
    writeCount++;
  }

  @override
  Future<void> updateUserSyncMetadata(String uid, DateTime nowUtc) async {}
  @override
  Future<void> deleteAllUserCloudData(String uid) async {}
}

class _MemorySyncLocalRepository implements SyncLocalRepository {
  _MemorySyncLocalRepository({String? linkedUid})
    : state = SyncState(
        deviceId: 'device-a',
        linkedUid: linkedUid,
        initialSyncCompleted: linkedUid != null,
        pendingCount: 0,
      );
  SyncState state;
  @override
  Future<SyncState> initialize() async => state;
  @override
  Future<SyncState> getState() async => state;
  @override
  Future<List<SyncEntity>> getSnapshot() async => const [];
  @override
  Future<SyncEntity?> getEntity(
    SyncEntityType type,
    String entityKey,
    String deviceId,
  ) async => null;
  @override
  Future<List<SyncOutboxOperation>> getPendingOperations({
    int limit = 400,
  }) async => const [];
  @override
  Future<void> setAttemptStarted(DateTime nowUtc) async {}
  @override
  Future<List<SyncEntity>> applyMerge({
    required List<SyncEntity> remoteWinners,
    required List<SyncEntity> localWinners,
    required DateTime nowUtc,
    String? linkedUid,
    bool markInitialSyncComplete = false,
  }) async {
    state = SyncState(
      deviceId: state.deviceId,
      linkedUid: linkedUid ?? state.linkedUid,
      initialSyncCompleted:
          markInitialSyncComplete || state.initialSyncCompleted,
      pendingCount: localWinners.length,
    );
    return remoteWinners;
  }

  @override
  Future<void> acknowledge(SyncOutboxOperation operation) async {}
  @override
  Future<void> recordFailure(
    SyncOutboxOperation operation,
    String errorCode,
  ) async {}
  @override
  Future<void> markSuccessfulSync(DateTime nowUtc) async {}
  @override
  Future<void> setError(String? errorCode, DateTime nowUtc) async {}
  @override
  Future<void> clearLinkForDeletedAccount(String uid) async {}
}
