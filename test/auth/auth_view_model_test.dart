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
  test(
    'email validation trims whitespace and accepts basic valid addresses',
    () {
      expect(isValidAuthEmail(' person@example.com '), isTrue);
      expect(isValidAuthEmail('not-an-email'), isFalse);
      expect(isValidAuthEmail('missing@domain'), isFalse);
    },
  );

  test(
    'create account remains successful when verification email fails',
    () async {
      final repository = FakeAuthRepository()
        ..verificationFailure = AuthFailure.networkUnavailable;
      final viewModel = AuthViewModel(repository);
      addTearDown(viewModel.dispose);
      addTearDown(repository.dispose);

      expect(
        await viewModel.createAccount('person@example.com', 'password123'),
        isTrue,
      );
      expect(viewModel.session, isA<AuthSignedIn>());
      expect(repository.verificationRequests, 1);
    },
  );

  test('sign-in failures map to calm domain feedback', () async {
    final repository = FakeAuthRepository()
      ..nextFailure = AuthFailure.invalidCredentials;
    final viewModel = AuthViewModel(repository);
    addTearDown(viewModel.dispose);
    addTearDown(repository.dispose);

    expect(await viewModel.signIn('person@example.com', 'wrong'), isFalse);
    expect(viewModel.failure, AuthFailure.invalidCredentials);
    expect(viewModel.message, 'Email atau kata sandi tidak cocok.');
  });

  test(
    'fake sign-in and sign-out leave persisted local data untouched',
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
      await viewModel.signIn('person@example.com', 'password123');
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
      expect(repository.signOutRequests, 1);
    },
  );
}
