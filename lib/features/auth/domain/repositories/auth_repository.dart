import '../models/auth_session.dart';
import '../models/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthSession> authStateChanges();
  Future<AuthSession> currentSession();
  Future<AuthUser> signInWithGoogle();
  Future<void> signOut();
  Future<void> retryAvailability();
}
