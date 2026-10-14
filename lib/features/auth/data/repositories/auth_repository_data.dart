import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_bootstrap_service.dart';

class AuthRepositoryData implements AuthRepository {
  AuthRepositoryData(this.service, [this.bootstrap]);
  final FirebaseAuthService service;
  final FirebaseBootstrapService? bootstrap;

  @override
  Stream<AuthSession> authStateChanges() => service.authStateChanges();
  @override
  Future<AuthSession> currentSession() async => service.currentSession();
  @override
  Future<AuthUser> signInWithGoogle() => service.signInWithGoogle();
  @override
  Future<AuthUser> signInWithApple() => service.signInWithApple();
  @override
  Future<AuthUser> reauthenticateWithGoogle() =>
      service.reauthenticateWithGoogle();
  @override
  Future<AuthUser> reauthenticateWithApple() =>
      service.reauthenticateWithApple();
  @override
  Future<void> revokeAppleAuthorizationToken() =>
      service.revokeAppleAuthorizationToken();
  @override
  Future<void> deleteCurrentUser() => service.deleteCurrentUser();
  @override
  Future<void> disconnectGoogle() => service.disconnectGoogle();
  @override
  Future<void> signOut() => service.signOut();
  @override
  Future<void> retryAvailability() async {
    final configured = await bootstrap?.initialize() ?? true;
    if (!configured) throw StateError('Firebase unavailable');
    service.attachDefault();
  }
}
