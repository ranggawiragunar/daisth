import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) {
    _auth = auth;
  }

  FirebaseAuth? _auth;
  final StreamController<AuthSession> _sessions = StreamController.broadcast();
  StreamSubscription<User?>? _authSubscription;
  bool get isAvailable => _auth != null;

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _sessions.close();
  }

  void attachDefault() {
    if (_auth != null) return;
    _auth = FirebaseAuth.instance;
    _sessions.add(_session(_auth!.currentUser));
    _authSubscription = _auth!.authStateChanges().listen(
      (user) => _sessions.add(_session(user)),
      onError: (_) => _sessions.add(const AuthUnavailable()),
    );
  }

  Stream<AuthSession> authStateChanges() {
    return Stream<AuthSession>.multi((controller) {
      controller.add(currentSession());
      final subscription = _sessions.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  AuthSession currentSession() =>
      _auth == null ? const AuthUnavailable() : _session(_auth!.currentUser);

  Future<AuthUser> signIn(String email, String password) async =>
      _mapOperation(() async {
        final result = await _auth!.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return _user(result.user!);
      });

  Future<AuthUser> createAccount(String email, String password) async =>
      _mapOperation(() async {
        final result = await _auth!.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        return _user(result.user!);
      });

  Future<void> sendPasswordReset(String email) =>
      _mapOperation(() => _auth!.sendPasswordResetEmail(email: email));

  Future<void> sendVerification() => _mapOperation(() async {
    final user = _auth?.currentUser;
    if (user == null) throw const AuthOperationException(AuthFailure.unknown);
    await user.sendEmailVerification();
  });

  Future<AuthUser?> reloadCurrentUser() => _mapOperation(() async {
    final user = _auth?.currentUser;
    if (user == null) return null;
    await user.reload();
    final refreshed = _auth?.currentUser;
    return refreshed == null ? null : _user(refreshed);
  });

  Future<void> signOut() => _mapOperation(() => _auth!.signOut());

  Future<T> _mapOperation<T>(Future<T> Function() operation) async {
    if (_auth == null) {
      throw const AuthOperationException(AuthFailure.serviceUnavailable);
    }
    try {
      return await operation();
    } on AuthOperationException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthOperationException(_failure(error.code));
    } on FirebaseException {
      throw const AuthOperationException(AuthFailure.serviceUnavailable);
    } catch (_) {
      throw const AuthOperationException(AuthFailure.unknown);
    }
  }

  AuthSession _session(User? user) =>
      user == null ? const AuthSignedOut() : AuthSignedIn(_user(user));

  AuthUser _user(User user) => AuthUser(
    uid: user.uid,
    email: user.email ?? '',
    emailVerified: user.emailVerified,
  );

  AuthFailure _failure(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => AuthFailure.invalidCredentials,
    'email-already-in-use' => AuthFailure.emailAlreadyInUse,
    'weak-password' => AuthFailure.weakPassword,
    'invalid-email' => AuthFailure.invalidEmail,
    'too-many-requests' => AuthFailure.tooManyRequests,
    'network-request-failed' => AuthFailure.networkUnavailable,
    'user-disabled' => AuthFailure.userDisabled,
    'operation-not-allowed' => AuthFailure.operationNotAllowed,
    _ => AuthFailure.unknown,
  };
}
