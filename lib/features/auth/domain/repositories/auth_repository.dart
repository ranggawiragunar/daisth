import '../models/auth_session.dart';
import '../models/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthSession> authStateChanges();
  Future<AuthSession> currentSession();
  Future<AuthUser> signInWithEmailPassword(String email, String password);
  Future<AuthUser> createAccountWithEmailPassword(
    String email,
    String password,
  );
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendVerificationEmail();
  Future<AuthUser?> reloadCurrentUser();
  Future<void> signOut();
  Future<void> retryAvailability();
}
