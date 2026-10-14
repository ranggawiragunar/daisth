import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/auth/domain/models/auth_session.dart';
import 'package:daisth/features/auth/domain/models/auth_user.dart';
import 'package:daisth/features/auth/domain/repositories/auth_repository.dart';
import 'package:daisth/features/auth/domain/use_cases/delete_account_use_case.dart';
import 'package:daisth/features/sync/domain/models/sync_entity.dart';
import 'package:daisth/features/sync/domain/repositories/cloud_data_repository.dart';
import 'package:daisth/features/sync/domain/repositories/sync_local_repository.dart';
import 'package:daisth/features/sync/domain/sync_coordinator.dart';

void main() {
  test(
    'linked account deletion purges cloud before auth and clears only link',
    () async {
      final h = await _Harness.create(linkedUid: 'user-a');
      addTearDown(h.coordinator.dispose);

      expect(await h.useCase('user-a'), DeleteAccountOutcome.success);
      expect(h.auth.events, ['reauth', 'auth-delete', 'disconnect']);
      expect(h.cloud.events, ['purge:user-a']);
      expect(h.local.events, ['unlink:user-a']);
      expect(h.local.state.linkedUid, isNull);
      expect(h.local.dataPreserved, isTrue);
    },
  );

  test('signed-in account without sync link can still be deleted', () async {
    final h = await _Harness.create();
    addTearDown(h.coordinator.dispose);

    expect(await h.useCase('user-a'), DeleteAccountOutcome.success);
    expect(h.cloud.events, ['purge:user-a']);
    expect(h.local.events, isEmpty);
  });

  test('reauthentication cancellation deletes nothing', () async {
    final h = await _Harness.create(linkedUid: 'user-a');
    addTearDown(h.coordinator.dispose);
    h.auth.reauthFailure = AuthFailure.cancelled;

    expect(await h.useCase('user-a'), DeleteAccountOutcome.cancelled);
    expect(h.cloud.events, isEmpty);
    expect(h.auth.events, ['reauth']);
    expect(h.local.state.linkedUid, 'user-a');
  });

  test('wrong Google account fails before cloud purge', () async {
    final h = await _Harness.create(linkedUid: 'user-a');
    addTearDown(h.coordinator.dispose);
    h.auth.reauthUser = const AuthUser(uid: 'user-b');

    expect(await h.useCase('user-a'), DeleteAccountOutcome.wrongAccount);
    expect(h.cloud.events, isEmpty);
    expect(h.auth.events, ['reauth']);
  });

  test('cloud purge failure preserves auth user and local linkage', () async {
    final h = await _Harness.create(linkedUid: 'user-a');
    addTearDown(h.coordinator.dispose);
    h.cloud.failPurge = true;

    expect(await h.useCase('user-a'), DeleteAccountOutcome.cloudDeleteFailed);
    expect(h.auth.events, ['reauth']);
    expect(h.local.state.linkedUid, 'user-a');
  });

  test('Firebase deletion failure keeps local link for retry', () async {
    final h = await _Harness.create(linkedUid: 'user-a');
    addTearDown(h.coordinator.dispose);
    h.auth.deleteFailure = AuthFailure.unknown;

    expect(await h.useCase('user-a'), DeleteAccountOutcome.accountDeleteFailed);
    expect(h.cloud.events, ['purge:user-a']);
    expect(h.local.state.linkedUid, 'user-a');
    expect(h.local.events, isEmpty);
  });

  test('requires-recent-login remains retryable after cloud purge', () async {
    final h = await _Harness.create(linkedUid: 'user-a');
    addTearDown(h.coordinator.dispose);
    h.auth.deleteFailure = AuthFailure.needsReauthentication;

    expect(
      await h.useCase('user-a'),
      DeleteAccountOutcome.needsReauthentication,
    );
    expect(h.cloud.events, ['purge:user-a']);
    expect(h.local.state.linkedUid, 'user-a');
  });

  test(
    'disconnect failure falls back to provider sign out after deletion',
    () async {
      final h = await _Harness.create();
      addTearDown(h.coordinator.dispose);
      h.auth.disconnectFails = true;

      expect(await h.useCase('user-a'), DeleteAccountOutcome.success);
      expect(h.auth.events, [
        'reauth',
        'auth-delete',
        'disconnect',
        'sign-out',
      ]);
    },
  );

  test('deleting current UID preserves a different local sync link', () async {
    final h = await _Harness.create(authUid: 'user-b', linkedUid: 'user-a');
    addTearDown(h.coordinator.dispose);

    expect(await h.useCase('user-b'), DeleteAccountOutcome.success);
    expect(h.cloud.events, ['purge:user-b']);
    expect(h.auth.events, ['reauth', 'auth-delete', 'disconnect']);
    expect(h.local.events, isEmpty);
    expect(h.local.state.linkedUid, 'user-a');
    expect(h.local.dataPreserved, isTrue);
  });

  test(
    'Apple deletion revokes Apple before purge and preserves local data',
    () async {
      final h = await _Harness.create(
        linkedUid: 'user-a',
        provider: AuthProviderKind.apple,
      );
      addTearDown(h.coordinator.dispose);

      expect(await h.useCase('user-a'), DeleteAccountOutcome.success);
      expect(h.auth.events, [
        'reauth-apple',
        'revoke-apple',
        'auth-delete',
        'sign-out',
      ]);
      expect(h.cloud.events, ['purge:user-a']);
      expect(h.local.events, ['unlink:user-a']);
      expect(h.local.state.linkedUid, isNull);
      expect(h.local.dataPreserved, isTrue);
    },
  );

  test(
    'Apple reauthentication cancellation leaves all data untouched',
    () async {
      final h = await _Harness.create(provider: AuthProviderKind.apple);
      addTearDown(h.coordinator.dispose);
      h.auth.reauthFailure = AuthFailure.cancelled;

      expect(await h.useCase('user-a'), DeleteAccountOutcome.cancelled);
      expect(h.auth.events, ['reauth-apple']);
      expect(h.cloud.events, isEmpty);
      expect(h.local.dataPreserved, isTrue);
    },
  );

  test(
    'Apple reauthentication failure stops before revocation and purge',
    () async {
      final h = await _Harness.create(provider: AuthProviderKind.apple);
      addTearDown(h.coordinator.dispose);
      h.auth.reauthFailure = AuthFailure.networkUnavailable;

      expect(
        await h.useCase('user-a'),
        DeleteAccountOutcome.networkUnavailable,
      );
      expect(h.auth.events, ['reauth-apple']);
      expect(h.cloud.events, isEmpty);
    },
  );

  test(
    'Apple token revocation failure prevents cloud and auth deletion',
    () async {
      final h = await _Harness.create(provider: AuthProviderKind.apple);
      addTearDown(h.coordinator.dispose);
      h.auth.revokeAppleFails = true;

      expect(
        await h.useCase('user-a'),
        DeleteAccountOutcome.appleTokenRevocationFailed,
      );
      expect(h.auth.events, ['reauth-apple', 'revoke-apple']);
      expect(h.cloud.events, isEmpty);
    },
  );

  test(
    'Apple cloud purge failure keeps Firebase user and local link',
    () async {
      final h = await _Harness.create(
        linkedUid: 'user-a',
        provider: AuthProviderKind.apple,
      );
      addTearDown(h.coordinator.dispose);
      h.cloud.failPurge = true;

      expect(await h.useCase('user-a'), DeleteAccountOutcome.cloudDeleteFailed);
      expect(h.auth.events, ['reauth-apple', 'revoke-apple']);
      expect(h.local.state.linkedUid, 'user-a');
      expect(h.local.dataPreserved, isTrue);
    },
  );

  test('Apple Firebase deletion failure keeps local link for retry', () async {
    final h = await _Harness.create(
      linkedUid: 'user-a',
      provider: AuthProviderKind.apple,
    );
    addTearDown(h.coordinator.dispose);
    h.auth.deleteFailure = AuthFailure.unknown;

    expect(await h.useCase('user-a'), DeleteAccountOutcome.accountDeleteFailed);
    expect(h.auth.events, ['reauth-apple', 'revoke-apple', 'auth-delete']);
    expect(h.cloud.events, ['purge:user-a']);
    expect(h.local.state.linkedUid, 'user-a');
    expect(h.local.dataPreserved, isTrue);
  });
}

class _Harness {
  _Harness(this.auth, this.cloud, this.local, this.coordinator)
    : useCase = DeleteAccountUseCase(
        authRepository: auth,
        cloudRepository: cloud,
        syncLocalRepository: local,
        syncCoordinator: coordinator,
      );

  final _Auth auth;
  final _Cloud cloud;
  final _Local local;
  final SyncCoordinator coordinator;
  final DeleteAccountUseCase useCase;

  static Future<_Harness> create({
    String authUid = 'user-a',
    String? linkedUid,
    AuthProviderKind provider = AuthProviderKind.google,
  }) async {
    final auth = _Auth(authUid, provider: provider);
    final local = _Local(linkedUid);
    final cloud = _Cloud();
    final coordinator = SyncCoordinator(
      authRepository: auth,
      localRepository: local,
      cloudRepository: cloud,
    );
    await coordinator.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    auth.events.clear();
    cloud.events.clear();
    local.events.clear();
    return _Harness(auth, cloud, local, coordinator);
  }
}

class _Auth implements AuthRepository {
  _Auth(this.uid, {this.provider = AuthProviderKind.google});
  final String uid;
  final AuthProviderKind provider;
  final events = <String>[];
  AuthFailure? reauthFailure;
  AuthFailure? deleteFailure;
  AuthUser? reauthUser;
  bool disconnectFails = false;
  bool revokeAppleFails = false;

  AuthSession get session =>
      AuthSignedIn(AuthUser(uid: uid, provider: provider));
  @override
  Stream<AuthSession> authStateChanges() => Stream.value(session);
  @override
  Future<AuthSession> currentSession() async => session;
  @override
  Future<AuthUser> signInWithGoogle() async =>
      AuthUser(uid: uid, provider: AuthProviderKind.google);
  @override
  Future<AuthUser> signInWithApple() async =>
      AuthUser(uid: uid, provider: AuthProviderKind.apple);
  @override
  Future<AuthUser> reauthenticateWithGoogle() async {
    events.add('reauth');
    if (reauthFailure case final failure?) {
      throw AuthOperationException(failure);
    }
    return reauthUser ?? AuthUser(uid: uid, provider: provider);
  }

  @override
  Future<AuthUser> reauthenticateWithApple() async {
    events.add('reauth-apple');
    if (reauthFailure case final failure?) {
      throw AuthOperationException(failure);
    }
    return reauthUser ?? AuthUser(uid: uid, provider: AuthProviderKind.apple);
  }

  @override
  Future<void> revokeAppleAuthorizationToken() async {
    events.add('revoke-apple');
    if (revokeAppleFails) throw StateError('Apple token revocation failed');
  }

  @override
  Future<void> deleteCurrentUser() async {
    events.add('auth-delete');
    if (deleteFailure case final failure?) {
      throw AuthOperationException(failure);
    }
  }

  @override
  Future<void> disconnectGoogle() async {
    events.add('disconnect');
    if (disconnectFails) throw StateError('disconnect failed');
  }

  @override
  Future<void> signOut() async => events.add('sign-out');
  @override
  Future<void> retryAvailability() async {}
}

class _Cloud implements CloudDataRepository {
  final events = <String>[];
  bool failPurge = false;
  @override
  Future<CloudDataset> fetchAccountDataset(String uid) async =>
      const CloudDataset(entities: []);
  @override
  Future<void> writeEntities(String uid, List<SyncEntity> entities) async {}
  @override
  Future<void> updateUserSyncMetadata(String uid, DateTime nowUtc) async {}
  @override
  Future<void> deleteAllUserCloudData(String uid) async {
    events.add('purge:$uid');
    if (failPurge) throw StateError('network unavailable');
  }
}

class _Local implements SyncLocalRepository {
  _Local(String? linkedUid)
    : state = SyncState(
        deviceId: 'stable-device',
        linkedUid: linkedUid,
        initialSyncCompleted: linkedUid != null,
        pendingCount: 0,
      );
  SyncState state;
  final events = <String>[];
  bool dataPreserved = true;
  @override
  Future<SyncState> initialize() async => state;
  @override
  Future<SyncState> getState() async => state;
  @override
  Future<List<SyncEntity>> getSnapshot() async => const [];
  @override
  Future<SyncEntity?> getEntity(
    SyncEntityType type,
    String key,
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
  }) async => const [];
  @override
  Future<void> acknowledge(SyncOutboxOperation operation) async {}
  @override
  Future<void> recordFailure(
    SyncOutboxOperation operation,
    String code,
  ) async {}
  @override
  Future<void> markSuccessfulSync(DateTime nowUtc) async {}
  @override
  Future<void> setError(String? code, DateTime nowUtc) async {}
  @override
  Future<void> clearLinkForDeletedAccount(String uid) async {
    events.add('unlink:$uid');
    if (state.linkedUid == uid) {
      state = SyncState(
        deviceId: state.deviceId,
        linkedUid: null,
        initialSyncCompleted: false,
        pendingCount: 0,
      );
    }
  }
}
