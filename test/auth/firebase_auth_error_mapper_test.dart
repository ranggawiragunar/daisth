import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/auth/data/services/firebase_auth_error_mapper.dart';
import 'package:daisth/features/auth/domain/models/auth_session.dart';

void main() {
  test('Firebase web flow cancellation maps to silent cancellation', () {
    expect(
      mapFirebaseAuthErrorCode('web-context-cancelled'),
      AuthFailure.cancelled,
    );
  });

  test('provider cancellation alias maps to silent cancellation', () {
    expect(mapFirebaseAuthErrorCode('user-cancelled'), AuthFailure.cancelled);
  });

  test('Firebase Apple errors retain retry and configuration categories', () {
    expect(
      mapFirebaseAuthErrorCode('network-request-failed'),
      AuthFailure.networkUnavailable,
    );
    expect(
      mapFirebaseAuthErrorCode('operation-not-allowed'),
      AuthFailure.configurationError,
    );
  });
}
