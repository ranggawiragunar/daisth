import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/auth_session.dart';
import '../domain/repositories/auth_repository.dart';

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

  Future<bool> signIn(String email, String password) => _run(() async {
    await repository.signInWithEmailPassword(email.trim(), password);
    return 'Berhasil masuk.';
  });

  Future<bool> createAccount(String email, String password) => _run(() async {
    final user = await repository.createAccountWithEmailPassword(
      email.trim(),
      password,
    );
    try {
      await repository.sendVerificationEmail();
    } catch (_) {
      // Account creation succeeded; verification can be retried from Account.
    }
    session = AuthSignedIn(user);
    return 'Akun berhasil dibuat.';
  });

  Future<bool> resetPassword(String email) => _run(() async {
    await repository.sendPasswordResetEmail(email.trim());
    return 'Jika alamat tersebut terdaftar, instruksi reset akan dikirim ke email itu.';
  });

  Future<bool> resendVerification() => _run(() async {
    await repository.sendVerificationEmail();
    return 'Email verifikasi telah diminta.';
  });

  Future<bool> refreshVerification() => _run(() async {
    final user = await repository.reloadCurrentUser();
    if (user != null) session = AuthSignedIn(user);
    return user?.emailVerified == true
        ? 'Email sudah diverifikasi.'
        : 'Email belum diverifikasi.';
  });

  Future<bool> signOut() => _run(() async {
    await repository.signOut();
    session = const AuthSignedOut();
    return 'Berhasil keluar.';
  });

  Future<bool> retryAvailability() async {
    operation = AuthOperationState.loading;
    notifyListeners();
    try {
      await repository.retryAvailability();
      await refreshSession();
      operation = AuthOperationState.success;
      message = 'Layanan akun siap.';
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
    AuthFailure.invalidCredentials => 'Email atau kata sandi tidak cocok.',
    AuthFailure.emailAlreadyInUse => 'Alamat email ini sudah digunakan.',
    AuthFailure.weakPassword => 'Gunakan kata sandi yang lebih kuat.',
    AuthFailure.invalidEmail => 'Periksa kembali alamat email.',
    AuthFailure.tooManyRequests => 'Terlalu banyak percobaan. Coba lagi nanti.',
    AuthFailure.networkUnavailable =>
      'Koneksi tidak tersedia. Coba lagi saat terhubung ke internet.',
    AuthFailure.userDisabled => 'Akun ini tidak dapat digunakan.',
    AuthFailure.operationNotAllowed => 'Metode akun belum tersedia.',
    AuthFailure.serviceUnavailable =>
      'Layanan akun belum tersedia di versi ini. Daisth tetap bisa digunakan.',
    AuthFailure.unknown => 'Terjadi kendala. Coba lagi.',
  };

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

bool isValidAuthEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
