import '../../domain/models/auth_session.dart';

AuthFailure mapFirebaseAuthErrorCode(String code) => switch (code) {
  'web-context-cancelled' || 'user-cancelled' => AuthFailure.cancelled,
  'network-request-failed' => AuthFailure.networkUnavailable,
  'requires-recent-login' => AuthFailure.needsReauthentication,
  'account-exists-with-different-credential' ||
  'invalid-credential' ||
  'user-mismatch' ||
  'credential-already-in-use' => AuthFailure.credentialRejected,
  'user-disabled' => AuthFailure.accountDisabled,
  'too-many-requests' => AuthFailure.tooManyRequests,
  'operation-not-allowed' ||
  'app-not-authorized' => AuthFailure.configurationError,
  'service-not-available' => AuthFailure.serviceUnavailable,
  _ => AuthFailure.unknown,
};
