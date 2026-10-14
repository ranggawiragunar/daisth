import '../models/auth_session.dart';
import '../models/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthSession> authStateChanges();
  Future<AuthSession> currentSession();
  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
  Future<AuthUser> reauthenticateWithGoogle();
  Future<AuthUser> reauthenticateWithApple();
  Future<void> revokeAppleAuthorizationToken();
  Future<void> deleteCurrentUser();
  Future<void> disconnectGoogle();
  Future<void> signOut();
  Future<void> retryAvailability();
}
