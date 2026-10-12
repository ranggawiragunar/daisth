import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:istiqam/app/app_preferences_scope.dart';
import 'package:istiqam/app/router/app_router.dart';
import 'package:istiqam/core/design_system/components/istiqam_notice_controller.dart';
import 'package:istiqam/core/design_system/theme/istiqam_theme.dart';
import 'package:istiqam/features/dhikr/presentation/screens/dhikr_counter_screen.dart';

void main() {
  testWidgets('Zuhur gates dhikr until the required prayer is complete', (
    tester,
  ) async {
    final harness = _DhikrRouterHarness(initialLocation: '/routines/zuhur');
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Available after prayer'), findsOneWidget);
    await tester.ensureVisible(find.text('Post-Prayer Dhikr'));
    await tester.tap(find.text('Post-Prayer Dhikr'));
    await tester.pumpAndSettle();
    expect(find.text('Selesaikan sholat terlebih dahulu'), findsOneWidget);
    expect(find.byType(DhikrCounterScreen), findsNothing);
    harness.noticeController.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark Zuhur Done'));
    await tester.pumpAndSettle();
    harness.noticeController.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('Mulai dzikir setelah sholat'), findsOneWidget);

    await tester.tap(find.text('Post-Prayer Dhikr'));
    await tester.pumpAndSettle();
    expect(find.byType(DhikrCounterScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);
    expect(find.text('Dzikir Setelah Sholat'), findsOneWidget);
    expect(find.text('Sahih Muslim 597a'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Recorded just now'), findsOneWidget);
    expect(find.byType(DhikrCounterScreen), findsNothing);
  });

  testWidgets('completed sequence returns its result to Routine Detail', (
    tester,
  ) async {
    final harness = _DhikrRouterHarness(initialLocation: '/routines/zuhur');
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark Zuhur Done'));
    await tester.pumpAndSettle();
    harness.noticeController.dismiss();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Post-Prayer Dhikr'));
    await tester.tap(find.text('Post-Prayer Dhikr'));
    await tester.pumpAndSettle();

    final countSurface = find.byKey(const ValueKey('dhikr-count-tap-surface'));
    await Scrollable.ensureVisible(
      tester.element(countSurface),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    for (var count = 0; count < 100; count++) {
      await Scrollable.ensureVisible(
        tester.element(countSurface),
        alignment: 0.5,
      );
      await tester.tap(countSurface);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();

    expect(find.text('Dzikir selesai'), findsOneWidget);
    expect(find.text('100 hitungan selesai'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.text('Recorded just now'), findsOneWidget);
    expect(find.text('Dzikir sudah tercatat'), findsOneWidget);
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
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dhikr-count-tap-surface')));
    await tester.pumpAndSettle();

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari sesi?'), findsOneWidget);
    expect(
      find.text('Progress dzikir sesi ini belum disimpan.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Lanjut Dzikir'));
    await tester.pumpAndSettle();
    expect(find.byType(DhikrCounterScreen), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.byType(DhikrCounterScreen), findsNothing);
    expect(find.text('Due now'), findsOneWidget);
  });

  testWidgets('reset session requires confirmation before clearing count', (
    tester,
  ) async {
    final harness = _DhikrRouterHarness(
      initialLocation: '/routines/zuhur/dhikr/post-prayer',
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    final countSurface = find.byKey(const ValueKey('dhikr-count-tap-surface'));
    await tester.ensureVisible(countSurface);
    await tester.tap(countSurface);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Pilihan sesi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset sesi'));
    await tester.pumpAndSettle();
    expect(find.text('Reset sesi?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Pilihan sesi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset sesi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset sesi'));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets(
    'unknown sequence is safe and counter fits light and dark at 320px',
    (tester) async {
      final unknown = _DhikrRouterHarness(
        initialLocation: '/routines/zuhur/dhikr/not-found',
      );
      await tester.pumpWidget(unknown.app);
      await tester.pumpAndSettle();
      expect(find.byType(DhikrUnavailableScreen), findsOneWidget);
      expect(find.text('Dzikir tidak tersedia'), findsOneWidget);
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
        await tester.pumpAndSettle();
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

class _DhikrRouterHarness {
  _DhikrRouterHarness({
    required String initialLocation,
    this.themeMode = ThemeMode.light,
  }) {
    router = createAppRouter(
      noticeController: noticeController,
      initialLocation: initialLocation,
    );
  }

  final ThemeMode themeMode;
  final noticeController = IstiqamNoticeController();
  late final GoRouter router;

  Widget get app => MaterialApp.router(
    theme: IstiqamTheme.light,
    darkTheme: IstiqamTheme.dark,
    themeMode: themeMode,
    routerConfig: router,
    builder: (context, child) => AppPreferencesScope(
      themeMode: themeMode,
      onThemeModeChanged: (_) {},
      child: IstiqamNoticeScope(
        controller: noticeController,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );

  void dispose() {
    router.dispose();
    noticeController.dispose();
  }
}
