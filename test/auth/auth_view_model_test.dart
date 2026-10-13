import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/features/auth/domain/models/auth_session.dart';
import 'package:daisth/features/auth/presentation/auth_view_model.dart';
import 'package:daisth/core/app_settings/domain/models/app_settings.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/reflection/domain/models/reflection_rhythm.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';

import '../support/fake_auth_repository.dart';
import '../support/test_persistence.dart';

void main() {
  test('Google sign-in updates the session with a plain AuthUser', () async {
    final repository = FakeAuthRepository();
    final viewModel = AuthViewModel(repository);
    addTearDown(viewModel.dispose);
    addTearDown(repository.dispose);

    expect(await viewModel.signInWithGoogle(), isTrue);
    final session = viewModel.session as AuthSignedIn;
    expect(session.user.uid, 'test-uid');
    expect(session.user.email, 'person@example.com');
    expect(session.user.displayName, 'Test User');
    expect(viewModel.message, 'Akun Google berhasil dihubungkan.');
  });

  test('Google sign-in failures map to calm domain feedback', () async {
    final repository = FakeAuthRepository()
      ..nextFailure = AuthFailure.networkUnavailable;
    final viewModel = AuthViewModel(repository);
    addTearDown(viewModel.dispose);
    addTearDown(repository.dispose);

    expect(await viewModel.signInWithGoogle(), isFalse);
    expect(viewModel.failure, AuthFailure.networkUnavailable);
    expect(
      viewModel.message,
      'Koneksi tidak tersedia. Coba lagi saat terhubung ke internet.',
    );
  });

  test('Google account picker cancellation returns quietly to idle', () async {
    final repository = FakeAuthRepository()
      ..nextFailure = AuthFailure.cancelled;
    final viewModel = AuthViewModel(repository);
    addTearDown(viewModel.dispose);
    addTearDown(repository.dispose);

    expect(await viewModel.signInWithGoogle(), isFalse);
    expect(viewModel.failure, AuthFailure.cancelled);
    expect(viewModel.message, isNull);
    expect(viewModel.operation, AuthOperationState.idle);
  });

  test(
    'Google sign-in and sign-out leave persisted local data untouched',
    () async {
      final persistence = await TestPersistence.create();
      addTearDown(persistence.dispose);
      final day = CalendarDay(year: 2026, month: 10, day: 12);
      await persistence.routineRecords.markCompleted(
        routine: RoutineDemoData.zuhur,
        day: day,
        now: DateTime.utc(2026, 10, 12, 5),
      );
      await persistence.reflections.saveReflection(
        day: day,
        rhythm: ReflectionRhythm.steady,
        note: 'Still here',
        now: DateTime.utc(2026, 10, 12, 8),
      );
      await persistence.appSettings.saveSettings(
        const AppSettings(
          themePreference: AppThemePreference.dark,
          remindersEnabled: true,
        ),
      );

      final repository = FakeAuthRepository();
      final viewModel = AuthViewModel(repository);
      addTearDown(viewModel.dispose);
      addTearDown(repository.dispose);
      await viewModel.signInWithGoogle();
      await viewModel.signOut();

      expect(
        (await persistence.routineRecords.getRoutineRecord(
          day,
          'zuhur',
        ))?.status.name,
        'completed',
      );
      expect(
        (await persistence.reflections.getReflection(day))?.note,
        'Still here',
      );
      final settings = await persistence.appSettings.getSettings();
      expect(settings.themePreference, AppThemePreference.dark);
      expect(settings.remindersEnabled, isTrue);
      expect(repository.googleSignInRequests, 1);
      expect(repository.signOutRequests, 1);
    },
  );
}
