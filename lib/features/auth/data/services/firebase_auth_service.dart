import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';
import 'firebase_auth_error_mapper.dart';

class FirebaseAuthService {
  factory FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) => FirebaseAuthService._(
    auth: auth,
    googleSignIn: googleSignIn ?? GoogleSignIn.instance,
  );

  FirebaseAuthService._({this._auth, required this._googleSignIn});

  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  static Future<void>? _googleInitialization;
  String? _pendingAppleAuthorizationCode;
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

  Stream<AuthSession> authStateChanges() =>
      Stream<AuthSession>.multi((controller) {
        controller.add(currentSession());
        final subscription = _sessions.stream.listen(
          controller.add,
          onError: controller.addError,
        );
        controller.onCancel = subscription.cancel;
      });

  AuthSession currentSession() =>
      _auth == null ? const AuthUnavailable() : _session(_auth!.currentUser);

  Future<AuthUser> signInWithGoogle() => _mapOperation(() async {
    await _ensureGoogleInitialized();
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthOperationException(AuthFailure.configurationError);
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth!.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw const AuthOperationException(AuthFailure.credentialRejected);
    }
    return _user(user, provider: AuthProviderKind.google);
  });

  Future<AuthUser> signInWithApple() => _mapOperation(() async {
    _requireApplePlatform();
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final result = await _auth!.signInWithProvider(provider);
    final user = result.user;
    if (user == null) {
      throw const AuthOperationException(AuthFailure.credentialRejected);
    }
    return _user(user, provider: AuthProviderKind.apple);
  });

  Future<AuthUser> reauthenticateWithGoogle() => _mapOperation(() async {
    await _ensureGoogleInitialized();
    final current = _auth!.currentUser;
    if (current == null) {
      throw const AuthOperationException(AuthFailure.serviceUnavailable);
    }
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthOperationException(AuthFailure.configurationError);
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await current.reauthenticateWithCredential(credential);
    final user = result.user;
    if (user == null || user.uid != current.uid) {
      throw const AuthOperationException(AuthFailure.credentialRejected);
    }
    return _user(user, provider: AuthProviderKind.google);
  });

  Future<AuthUser> reauthenticateWithApple() => _mapOperation(() async {
    _requireApplePlatform();
    final current = _auth!.currentUser;
    if (current == null) {
      throw const AuthOperationException(AuthFailure.serviceUnavailable);
    }
    _pendingAppleAuthorizationCode = null;
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final result = await current.reauthenticateWithProvider(provider);
    final user = result.user;
    if (user == null ||
        user.uid != current.uid ||
        _auth!.currentUser?.uid != current.uid) {
      throw const AuthOperationException(AuthFailure.credentialRejected);
    }
    _pendingAppleAuthorizationCode =
        result.additionalUserInfo?.authorizationCode;
    if (_pendingAppleAuthorizationCode == null ||
        _pendingAppleAuthorizationCode!.isEmpty) {
      throw const AuthOperationException(AuthFailure.configurationError);
    }
    return _user(user, provider: AuthProviderKind.apple);
  });

  Future<void> revokeAppleAuthorizationToken() => _mapOperation(() async {
    _requireApplePlatform();
    final authorizationCode = _pendingAppleAuthorizationCode;
    if (authorizationCode == null || authorizationCode.isEmpty) {
      throw const AuthOperationException(AuthFailure.configurationError);
    }
    try {
      await _auth!.revokeTokenWithAuthorizationCode(authorizationCode);
    } finally {
      _pendingAppleAuthorizationCode = null;
    }
  });

  Future<void> deleteCurrentUser() => _mapOperation(() async {
    final current = _auth!.currentUser;
    if (current == null) {
      throw const AuthOperationException(AuthFailure.serviceUnavailable);
    }
    await current.delete();
  });

  Future<void> disconnectGoogle() => _mapOperation(() async {
    await _ensureGoogleInitialized();
    await _googleSignIn.disconnect();
  });

  Future<void> signOut() => _mapOperation(() async {
    await _auth!.signOut();
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Firebase sign-out must still complete if provider cleanup is unavailable.
    }
  });

  Future<void> _ensureGoogleInitialized() =>
      _googleInitialization ??= _googleSignIn.initialize();

  void _requireApplePlatform() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw const AuthOperationException(AuthFailure.serviceUnavailable);
    }
  }

  Future<T> _mapOperation<T>(Future<T> Function() operation) async {
    if (_auth == null) {
      throw const AuthOperationException(AuthFailure.serviceUnavailable);
    }
    try {
      return await operation();
    } on AuthOperationException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw AuthOperationException(_googleFailure(error.code));
    } on FirebaseAuthException catch (error) {
      throw AuthOperationException(mapFirebaseAuthErrorCode(error.code));
    } on FirebaseException {
      throw const AuthOperationException(AuthFailure.serviceUnavailable);
    } catch (_) {
      throw const AuthOperationException(AuthFailure.unknown);
    }
  }

  AuthSession _session(User? user) =>
      user == null ? const AuthSignedOut() : AuthSignedIn(_user(user));

  AuthUser _user(User user, {AuthProviderKind? provider}) => AuthUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    provider:
        provider ??
        (user.providerData.any((info) => info.providerId == 'apple.com')
            ? AuthProviderKind.apple
            : AuthProviderKind.google),
  );

  AuthFailure _googleFailure(GoogleSignInExceptionCode code) => switch (code) {
    GoogleSignInExceptionCode.canceled ||
    GoogleSignInExceptionCode.interrupted => AuthFailure.cancelled,
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError =>
      AuthFailure.configurationError,
    GoogleSignInExceptionCode.uiUnavailable => AuthFailure.serviceUnavailable,
    GoogleSignInExceptionCode.userMismatch => AuthFailure.credentialRejected,
    GoogleSignInExceptionCode.unknownError => AuthFailure.unknown,
  };
}
