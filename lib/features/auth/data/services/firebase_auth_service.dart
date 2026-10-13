import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';

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
    return _user(user);
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
      throw AuthOperationException(_firebaseFailure(error.code));
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
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
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

  AuthFailure _firebaseFailure(String code) => switch (code) {
    'network-request-failed' => AuthFailure.networkUnavailable,
    'account-exists-with-different-credential' ||
    'invalid-credential' ||
    'credential-already-in-use' => AuthFailure.credentialRejected,
    'user-disabled' => AuthFailure.accountDisabled,
    'too-many-requests' => AuthFailure.tooManyRequests,
    'operation-not-allowed' ||
    'app-not-authorized' => AuthFailure.configurationError,
    'service-not-available' => AuthFailure.serviceUnavailable,
    _ => AuthFailure.unknown,
  };
}
