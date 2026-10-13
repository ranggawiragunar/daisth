import 'dart:async';

import 'package:daisth/features/auth/domain/models/auth_session.dart';
import 'package:daisth/features/auth/domain/models/auth_user.dart';
import 'package:daisth/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  final controller = StreamController<AuthSession>.broadcast();
  AuthSession session = const AuthSignedOut();
  AuthFailure? nextFailure;
  int googleSignInRequests = 0;
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
  Future<AuthUser> signInWithGoogle() async {
    googleSignInRequests++;
    _failIfNeeded();
    const user = AuthUser(
      uid: 'test-uid',
      email: 'person@example.com',
      displayName: 'Test User',
      photoUrl: null,
    );
    _emit(const AuthSignedIn(user));
    return user;
  }

  @override
  Future<AuthUser> reauthenticateWithGoogle() => signInWithGoogle();

  @override
  Future<void> deleteCurrentUser() async => signOut();

  @override
  Future<void> disconnectGoogle() async {}

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
