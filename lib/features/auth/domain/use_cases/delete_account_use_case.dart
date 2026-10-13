import '../models/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../../../sync/domain/repositories/cloud_data_repository.dart';
import '../../../sync/domain/repositories/sync_local_repository.dart';
import '../../../sync/domain/sync_coordinator.dart';

enum DeleteAccountOutcome {
  success,
  cancelled,
  wrongAccount,
  needsReauthentication,
  networkUnavailable,
  cloudDeleteFailed,
  accountDeleteFailed,
  serviceUnavailable,
}

class DeleteAccountUseCase {
  const DeleteAccountUseCase({
    required this.authRepository,
    required this.cloudRepository,
    required this.syncLocalRepository,
    required this.syncCoordinator,
  });

  final AuthRepository authRepository;
  final CloudDataRepository cloudRepository;
  final SyncLocalRepository syncLocalRepository;
  final SyncCoordinator syncCoordinator;

  Future<DeleteAccountOutcome> call(
    String expectedUid,
  ) => syncCoordinator.runAccountDeletion(expectedUid, () async {
    final session = await authRepository.currentSession();
    if (session is! AuthSignedIn || session.user.uid != expectedUid) {
      return DeleteAccountOutcome.wrongAccount;
    }

    try {
      final reauthenticated = await authRepository.reauthenticateWithGoogle();
      if (reauthenticated.uid != expectedUid) {
        return DeleteAccountOutcome.wrongAccount;
      }
    } on AuthOperationException catch (error) {
      return switch (error.failure) {
        AuthFailure.cancelled => DeleteAccountOutcome.cancelled,
        AuthFailure.credentialRejected => DeleteAccountOutcome.wrongAccount,
        AuthFailure.networkUnavailable =>
          DeleteAccountOutcome.networkUnavailable,
        AuthFailure.serviceUnavailable || AuthFailure.configurationError =>
          DeleteAccountOutcome.serviceUnavailable,
        _ => DeleteAccountOutcome.needsReauthentication,
      };
    } catch (_) {
      return DeleteAccountOutcome.serviceUnavailable;
    }

    try {
      await cloudRepository.deleteAllUserCloudData(expectedUid);
    } catch (_) {
      return DeleteAccountOutcome.cloudDeleteFailed;
    }

    try {
      await authRepository.deleteCurrentUser();
    } on AuthOperationException catch (error) {
      return switch (error.failure) {
        AuthFailure.needsReauthentication =>
          DeleteAccountOutcome.needsReauthentication,
        AuthFailure.networkUnavailable =>
          DeleteAccountOutcome.networkUnavailable,
        AuthFailure.serviceUnavailable =>
          DeleteAccountOutcome.serviceUnavailable,
        _ => DeleteAccountOutcome.accountDeleteFailed,
      };
    } catch (_) {
      return DeleteAccountOutcome.accountDeleteFailed;
    }

    final localState = await syncLocalRepository.getState();
    if (localState.linkedUid == expectedUid) {
      await syncLocalRepository.clearLinkForDeletedAccount(expectedUid);
    }
    try {
      await authRepository.disconnectGoogle();
    } catch (_) {
      try {
        await authRepository.signOut();
      } catch (_) {
        // The Firebase user is already deleted; provider cleanup is best effort.
      }
    }
    return DeleteAccountOutcome.success;
  });
}
