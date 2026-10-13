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
  Future<AuthUser> signInWithEmailPassword(String email, String password) =>
      service.signIn(email, password);
  @override
  Future<AuthUser> createAccountWithEmailPassword(
    String email,
    String password,
  ) => service.createAccount(email, password);
  @override
  Future<void> sendPasswordResetEmail(String email) =>
      service.sendPasswordReset(email);
  @override
  Future<void> sendVerificationEmail() => service.sendVerification();
  @override
  Future<AuthUser?> reloadCurrentUser() => service.reloadCurrentUser();
  @override
  Future<void> signOut() => service.signOut();
  @override
  Future<void> retryAvailability() async {
    final configured = await bootstrap?.initialize() ?? true;
    if (!configured) throw StateError('Firebase unavailable');
    service.attachDefault();
  }
}
