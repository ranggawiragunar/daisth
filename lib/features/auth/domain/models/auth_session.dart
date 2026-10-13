import 'auth_user.dart';

sealed class AuthSession {
  const AuthSession();
}

final class AuthSignedOut extends AuthSession {
  const AuthSignedOut();
}

final class AuthSignedIn extends AuthSession {
  const AuthSignedIn(this.user);
  final AuthUser user;
}

final class AuthUnavailable extends AuthSession {
  const AuthUnavailable();
}

enum AuthFailure {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
  networkUnavailable,
  userDisabled,
  operationNotAllowed,
  serviceUnavailable,
  unknown,
}

class AuthOperationException implements Exception {
  const AuthOperationException(this.failure);
  final AuthFailure failure;
}
