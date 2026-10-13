import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:daisth/app/app_preferences_scope.dart';
import 'package:daisth/app/dependencies/app_dependencies.dart';
import 'package:daisth/app/router/app_router.dart';
import 'package:daisth/app/router/route_paths.dart';
import 'package:daisth/core/app_settings/domain/models/app_settings.dart';
import 'package:daisth/core/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/features/onboarding/presentation/onboarding_screen.dart';

import '../support/fake_reflection_repository.dart';
import '../support/fake_routine_repository.dart';
import '../support/test_persistence.dart';

void main() {
  testWidgets(
    'onboarding pages explain routines, reflection, and optional account',
    (tester) async {
      final notices = DaisthNoticeController();
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: DaisthTheme.light,
          home: OnboardingScreen(
            completeOnboarding: () async {
              completed = true;
            },
            notices: notices,
          ),
        ),
      );
      expect(find.text('Jaga ritme yang penting'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Rutinitas yang mengikuti harimu'), findsOneWidget);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Catat tanpa menghakimi'), findsOneWidget);
      expect(find.textContaining('Akun tetap pilihan'), findsOneWidget);
      expect(completed, isFalse);
      notices.dispose();
    },
  );

  testWidgets('fresh install can skip onboarding and proceed to Today', (
    tester,
  ) async {
    final settings = _MemorySettings();
    final dependencies = AppDependencies(
      appSettingsRepository: settings,
      databaseService: TestPersistence.createDatabaseService(),
      routineRepository: FakeRoutineRepository(),
      reflectionRepository: FakeReflectionRepository(),
      startTodayClock: false,
    );
    final notices = DaisthNoticeController();
    final router = createAppRouter(
      noticeController: notices,
      dependencies: dependencies,
    );
    addTearDown(router.dispose);
    addTearDown(dependencies.dispose);
    addTearDown(notices.dispose);
    await tester.pumpWidget(_app(router, notices));
    await tester.pumpAndSettle();

    expect(find.text('Jaga ritme yang penting'), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);
    await tester.tap(find.text('Lewati'));
    await _pumpRoute(tester);
    expect(settings.onboardingVersion, 1);
    expect(find.byKey(const ValueKey('navigation-today')), findsOneWidget);
  });

  testWidgets('optional sign-in does not guard signed-out app routes', (
    tester,
  ) async {
    final settings = _MemorySettings()..onboardingVersion = 1;
    final dependencies = AppDependencies(
      appSettingsRepository: settings,
      databaseService: TestPersistence.createDatabaseService(),
      routineRepository: FakeRoutineRepository(),
      reflectionRepository: FakeReflectionRepository(),
      startTodayClock: false,
    );
    final notices = DaisthNoticeController();
    final router = createAppRouter(
      noticeController: notices,
      dependencies: dependencies,
      initialLocation: RoutePaths.today,
    );
    addTearDown(router.dispose);
    addTearDown(dependencies.dispose);
    addTearDown(notices.dispose);
    await tester.pumpWidget(_app(router, notices));
    await _pumpRoute(tester);
    expect(find.byKey(const ValueKey('navigation-today')), findsOneWidget);

    router.go(RoutePaths.history);
    await _pumpRoute(tester);
    expect(find.byKey(const ValueKey('navigation-history')), findsOneWidget);
    router.go(RoutePaths.routines);
    await _pumpRoute(tester);
    expect(find.byKey(const ValueKey('navigation-routines')), findsOneWidget);
    expect(find.text('Masuk'), findsNothing);
  });
}

Widget _app(GoRouter router, DaisthNoticeController notices) =>
    MaterialApp.router(
      theme: DaisthTheme.light,
      routerConfig: router,
      builder: (context, child) => AppPreferencesScope(
        themeMode: ThemeMode.system,
        onThemeModeChanged: (_) {},
        child: DaisthNoticeScope(
          controller: notices,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _MemorySettings implements AppSettingsRepository {
  int? onboardingVersion;
  @override
  Future<AppSettings> getSettings() async =>
      AppSettings(onboardingVersion: onboardingVersion);
  @override
  Future<void> saveSettings(AppSettings settings) async {}
  @override
  Future<int?> getOnboardingVersion() async => onboardingVersion;
  @override
  Future<void> setOnboardingVersion(int version) async =>
      onboardingVersion = version;
}
