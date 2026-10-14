import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/auth_session.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/use_cases/delete_account_use_case.dart';

enum AuthOperationState { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this.repository) {
    _subscription = repository.authStateChanges().listen(
      (session) {
        this.session = session;
        notifyListeners();
      },
      onError: (_) {
        session = const AuthUnavailable();
        notifyListeners();
      },
    );
    unawaited(refreshSession());
  }

  final AuthRepository repository;
  late final StreamSubscription<AuthSession> _subscription;
  AuthSession session = const AuthUnavailable();
  AuthOperationState operation = AuthOperationState.idle;
  AuthFailure? failure;
  String? message;

  Future<void> refreshSession() async {
    try {
      session = await repository.currentSession();
    } catch (_) {
      session = const AuthUnavailable();
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() => _run(() async {
    await repository.signInWithGoogle();
    return 'Akun Google berhasil dihubungkan.';
  });

  Future<bool> signInWithApple() => _run(() async {
    await repository.signInWithApple();
    return 'Akun Apple berhasil dihubungkan.';
  });

  Future<bool> signOut() => _run(() async {
    await repository.signOut();
    session = const AuthSignedOut();
    return 'Berhasil keluar.';
  });

  Future<bool> retryAvailability() async {
    operation = AuthOperationState.loading;
    failure = null;
    message = null;
    notifyListeners();
    try {
      await repository.retryAvailability();
      await refreshSession();
      operation = AuthOperationState.success;
      message = 'Layanan akun siap.';
      notifyListeners();
      return session is! AuthUnavailable;
    } catch (_) {
      session = const AuthUnavailable();
      operation = AuthOperationState.error;
      failure = AuthFailure.serviceUnavailable;
      message = _failureMessage(failure!);
      notifyListeners();
      return false;
    }
  }

  Future<bool> _run(Future<String> Function() action) async {
    if (operation == AuthOperationState.loading) return false;
    operation = AuthOperationState.loading;
    failure = null;
    message = null;
    notifyListeners();
    try {
      message = await action();
      operation = AuthOperationState.success;
      notifyListeners();
      return true;
    } on AuthOperationException catch (error) {
      failure = error.failure;
      if (error.failure == AuthFailure.cancelled) {
        operation = AuthOperationState.idle;
        notifyListeners();
        return false;
      }
      message = _failureMessage(error.failure);
    } catch (_) {
      failure = AuthFailure.unknown;
      message = _failureMessage(failure!);
    }
    operation = AuthOperationState.error;
    notifyListeners();
    return false;
  }

  String _failureMessage(AuthFailure failure) => switch (failure) {
    AuthFailure.cancelled => '',
    AuthFailure.networkUnavailable =>
      'Koneksi tidak tersedia. Coba lagi saat terhubung ke internet.',
    AuthFailure.configurationError =>
      'Pilihan akun belum dapat digunakan. Coba lagi nanti.',
    AuthFailure.credentialRejected =>
      'Akun ini tidak dapat digunakan. Coba pilih akun lain.',
    AuthFailure.accountDisabled => 'Akun ini tidak dapat digunakan.',
    AuthFailure.tooManyRequests => 'Terlalu banyak percobaan. Coba lagi nanti.',
    AuthFailure.needsReauthentication =>
      'Verifikasi ulang akun untuk melanjutkan.',
    AuthFailure.serviceUnavailable =>
      'Layanan akun belum tersedia. Daisth tetap bisa digunakan.',
    AuthFailure.unknown => 'Terjadi kendala. Coba lagi.',
  };

  Future<DeleteAccountOutcome> deleteAccount(
    DeleteAccountUseCase useCase,
    String uid,
  ) async {
    if (operation == AuthOperationState.loading) {
      return DeleteAccountOutcome.accountDeleteFailed;
    }
    operation = AuthOperationState.loading;
    failure = null;
    message = null;
    notifyListeners();
    DeleteAccountOutcome outcome;
    try {
      outcome = await useCase(uid);
      if (outcome == DeleteAccountOutcome.success) {
        await refreshSession();
        message = 'Akun Daisth telah dihapus. Data di perangkat tetap ada.';
        operation = AuthOperationState.success;
      } else if (outcome == DeleteAccountOutcome.cancelled) {
        operation = AuthOperationState.idle;
      } else {
        message = switch (outcome) {
          DeleteAccountOutcome.wrongAccount =>
            'Gunakan akun yang saat ini terhubung ke Daisth.',
          DeleteAccountOutcome.needsReauthentication =>
            'Verifikasi ulang akun Daisth, lalu coba lagi.',
          DeleteAccountOutcome.networkUnavailable ||
          DeleteAccountOutcome.cloudDeleteFailed =>
            'Akun belum dapat dihapus. Data di perangkat tetap aman. Coba lagi saat koneksi tersedia.',
          DeleteAccountOutcome.accountDeleteFailed =>
            'Akun belum dapat dihapus. Data di perangkat tetap aman. Coba lagi.',
          DeleteAccountOutcome.appleTokenRevocationFailed =>
            'Izin Apple belum dapat dicabut. Akun dan data masih aman; coba lagi.',
          DeleteAccountOutcome.serviceUnavailable =>
            'Layanan akun belum tersedia. Data di perangkat tetap aman.',
          DeleteAccountOutcome.success || DeleteAccountOutcome.cancelled => '',
        };
        operation = AuthOperationState.error;
      }
    } catch (_) {
      outcome = DeleteAccountOutcome.accountDeleteFailed;
      message =
          'Akun belum dapat dihapus. Data di perangkat tetap aman. Coba lagi.';
      operation = AuthOperationState.error;
    }
    notifyListeners();
    return outcome;
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
