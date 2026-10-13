import 'dart:async';

import 'package:daisth/features/auth/domain/models/auth_session.dart';
import 'package:daisth/features/auth/domain/models/auth_user.dart';
import 'package:daisth/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  final controller = StreamController<AuthSession>.broadcast();
  AuthSession session = const AuthSignedOut();
  AuthFailure? nextFailure;
  AuthFailure? verificationFailure;
  int verificationRequests = 0;
  int signOutRequests = 0;

  void _emit(AuthSession value) {
    session = value;
    controller.add(value);
  }

  @override
  Stream<AuthSession> authStateChanges() => controller.stream;
  @override
  Future<AuthSession> currentSession() async => session;
  @override
  Future<AuthUser> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    _failIfNeeded();
    const user = AuthUser(
      uid: 'test-uid',
      email: 'person@example.com',
      emailVerified: false,
    );
    _emit(const AuthSignedIn(user));
    return user;
  }

  @override
  Future<AuthUser> createAccountWithEmailPassword(
    String email,
    String password,
  ) async {
    _failIfNeeded();
    const user = AuthUser(
      uid: 'test-uid',
      email: 'person@example.com',
      emailVerified: false,
    );
    _emit(const AuthSignedIn(user));
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async => _failIfNeeded();
  @override
  Future<void> sendVerificationEmail() async {
    verificationRequests++;
    final failure = verificationFailure;
    verificationFailure = null;
    if (failure != null) throw AuthOperationException(failure);
  }

  @override
  Future<AuthUser?> reloadCurrentUser() async => const AuthUser(
    uid: 'test-uid',
    email: 'person@example.com',
    emailVerified: true,
  );
  @override
  Future<void> signOut() async {
    signOutRequests++;
    _failIfNeeded();
    _emit(const AuthSignedOut());
  }

  @override
  Future<void> retryAvailability() async {}

  void _failIfNeeded() {
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw AuthOperationException(failure);
  }

  Future<void> dispose() => controller.close();
}
