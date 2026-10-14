import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:daisth/app/app_preferences_scope.dart';
import 'package:daisth/app/dependencies/app_dependencies.dart';
import '../support/fake_routine_record_repository.dart';
import 'package:daisth/app/router/app_router.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/features/dhikr/presentation/screens/dhikr_counter_screen.dart';
import '../support/fake_routine_repository.dart';

void main() {
  testWidgets('Zuhur gates dhikr until the required prayer is complete', (
    tester,
  ) async {
    final harness = _DhikrRouterHarness(initialLocation: '/routines/zuhur');
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await _settle(tester);

    expect(find.text('Available after prayer'), findsOneWidget);
    await tester.ensureVisible(find.text('Zikir after prayer'));
    await tester.tap(find.text('Zikir after prayer'));
    await _settle(tester);
    expect(find.text('Complete the prayer first'), findsOneWidget);
    expect(find.byType(DhikrCounterScreen), findsNothing);
    harness.noticeController.dismiss();
    await _settle(tester);

    await tester.tap(find.text('Mark Dhuhr Done'));
    await _settle(tester);
    harness.noticeController.dismiss();
    await _settle(tester);
    expect(find.text('Start Zikir after prayer'), findsOneWidget);

    await tester.tap(find.text('Zikir after prayer'));
    await _settle(tester);
    expect(find.byType(DhikrCounterScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);
    expect(find.text('Zikir setelah salat'), findsOneWidget);
    expect(find.text('Sahih Muslim 597a'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await _settle(tester);
    expect(find.text('Recorded just now'), findsOneWidget);
    expect(find.byType(DhikrCounterScreen), findsNothing);
  });

  testWidgets('completed sequence returns its result to Routine Detail', (
    tester,
  ) async {
    final harness = _DhikrRouterHarness(initialLocation: '/routines/zuhur');
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await _settle(tester);

    await tester.tap(find.text('Mark Dhuhr Done'));
    await _settle(tester);
    harness.noticeController.dismiss();
    await _settle(tester);
    await tester.ensureVisible(find.text('Zikir after prayer'));
    await tester.tap(find.text('Zikir after prayer'));
    await _settle(tester);

    final countSurface = find.byKey(const ValueKey('dhikr-count-tap-surface'));
    await Scrollable.ensureVisible(
      tester.element(countSurface),
      alignment: 0.5,
    );
    await _settle(tester);
    for (var count = 0; count < 100; count++) {
      await Scrollable.ensureVisible(
        tester.element(countSurface),
        alignment: 0.5,
      );
      await tester.tap(countSurface);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await _settle(tester);

    expect(find.text('Zikir complete'), findsOneWidget);
    expect(find.text('100 counts completed'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await _settle(tester);

    expect(find.text('Recorded just now'), findsOneWidget);
    expect(find.text('Zikir recorded'), findsOneWidget);
    expect(find.byType(DhikrCounterScreen), findsNothing);
    final semantics = tester.ensureSemantics();
    try {
      final optionalDhikrStep = tester.getSemantics(
        find.byKey(const ValueKey('routine-step-toggle-post-prayer-dhikr')),
      );
      expect(optionalDhikrStep.flagsCollection.isChecked, CheckedState.isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('unfinished system back asks before discarding progress', (
    tester,
  ) async {
    final harness = _DhikrRouterHarness(
      initialLocation: '/routines/zuhur/dhikr/post-prayer',
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('dhikr-count-tap-surface')));
    await _settle(tester);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await _settle(tester);
    expect(find.text('Leave this session?'), findsOneWidget);
    expect(
      find.text('This Zikir session progress has not been saved.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue Zikir'));
    await _settle(tester);
    expect(find.byType(DhikrCounterScreen), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await _settle(tester);
    await tester.tap(find.text('Leave'));
    await _settle(tester);
    expect(find.byType(DhikrCounterScreen), findsNothing);
    expect(find.text('Not started'), findsOneWidget);
  });

  testWidgets('reset session requires confirmation before clearing count', (
    tester,
  ) async {
    final harness = _DhikrRouterHarness(
      initialLocation: '/routines/zuhur/dhikr/post-prayer',
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await _settle(tester);

    final countSurface = find.byKey(const ValueKey('dhikr-count-tap-surface'));
    await tester.ensureVisible(countSurface);
    await tester.tap(countSurface);
    await _settle(tester);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Session options'));
    await _settle(tester);
    await tester.tap(find.text('Reset session'));
    await _settle(tester);
    expect(find.text('Reset session?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Session options'));
    await _settle(tester);
    await tester.tap(find.text('Reset session'));
    await _settle(tester);
    await tester.tap(find.text('Reset session'));
    await _settle(tester);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets(
    'unknown sequence is safe and counter fits light and dark at 320px',
    (tester) async {
      final unknown = _DhikrRouterHarness(
        initialLocation: '/routines/zuhur/dhikr/not-found',
      );
      await tester.pumpWidget(unknown.app);
      await _settle(tester);
      expect(find.byType(DhikrUnavailableScreen), findsOneWidget);
      expect(find.text('Zikir is unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      unknown.dispose();

      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        final harness = _DhikrRouterHarness(
          initialLocation: '/routines/zuhur/dhikr/post-prayer',
          themeMode: mode,
        );
        await tester.pumpWidget(harness.app);
        await _settle(tester);
        expect(
          harness.router.routeInformationProvider.value.uri.path,
          '/routines/zuhur/dhikr/post-prayer',
        );
        expect(find.byType(DhikrCounterScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('navigation-today')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        harness.dispose();
      }
    },
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

class _DhikrRouterHarness {
  _DhikrRouterHarness({
    required String initialLocation,
    this.themeMode = ThemeMode.light,
  }) {
    router = createAppRouter(
      noticeController: noticeController,
      dependencies: dependencies,
      initialLocation: initialLocation,
      enforceOnboarding: false,
    );
  }

  final ThemeMode themeMode;
  final noticeController = DaisthNoticeController();
  final dependencies = AppDependencies(
    routineRepository: FakeRoutineRepository(),
    routineRecordRepository: FakeRoutineRecordRepository(),
    startTodayClock: false,
  );
  late final GoRouter router;

  Widget get app => MaterialApp.router(
    theme: DaisthTheme.light,
    darkTheme: DaisthTheme.dark,
    themeMode: themeMode,
    routerConfig: router,
    builder: (context, child) => AppPreferencesScope(
      themeMode: themeMode,
      onThemeModeChanged: (_) {},
      child: DaisthNoticeScope(
        controller: noticeController,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );

  void dispose() {
    router.dispose();
    dependencies.dispose();
    noticeController.dispose();
  }
}
