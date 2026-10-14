import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:daisth/app/app_preferences_scope.dart';
import 'package:daisth/app/dependencies/app_dependencies.dart';
import '../support/fake_routine_record_repository.dart';
import 'package:daisth/app/router/app_router.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/reader/presentation/screens/reader_screen.dart';
import '../support/fake_routine_repository.dart';

void main() {
  testWidgets('opening a bedtime reading does not complete its step', (
    tester,
  ) async {
    final harness = _ReaderRouterHarness(
      initialLocation: '/routines/penutup-hari',
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ayat Kursi'));
    await tester.tap(find.text('Ayat Kursi').last);
    await tester.pumpAndSettle();

    expect(
      harness.router.routeInformationProvider.value.uri.path,
      '/routines/penutup-hari/reader/ayat-kursi',
    );
    expect(find.text('Ayat Kursi'), findsOneWidget);
    expect(
      await harness.dependencies.routineRecordRepository.getStepRecords(
        CalendarDay.fromDateTime(DateTime.now()),
        'penutup-hari',
      ),
      isEmpty,
    );

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(ReaderScreen), findsNothing);
    expect(
      await harness.dependencies.routineRecordRepository.getStepRecords(
        CalendarDay.fromDateTime(DateTime.now()),
        'penutup-hari',
      ),
      isEmpty,
    );
  });

  testWidgets('Reader opens from Routine Detail and back preserves it', (
    tester,
  ) async {
    final harness = _ReaderRouterHarness(
      initialLocation: '/routines/sholat-malam',
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum dimulai'), findsOneWidget);

    await tester.ensureVisible(find.text('Doa Sebelum Tidur'));
    await tester.tap(
      find.byKey(const ValueKey('routine-link-Doa Sebelum Tidur')),
    );
    await tester.pumpAndSettle();

    expect(
      harness.router.routeInformationProvider.value.uri.path,
      '/routines/sholat-malam/reader/doa-sebelum-tidur',
    );
    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      '/routines/sholat-malam',
    );
    expect(find.text('Belum dimulai'), findsOneWidget);
  });

  testWidgets('direct Reader route renders content and display controls', (
    tester,
  ) async {
    final harness = _ReaderRouterHarness(
      initialLocation: '/routines/sholat-malam/reader/doa-sebelum-tidur',
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Doa Sebelum Tidur'), findsOneWidget);
    expect(find.text('Dibaca ketika hendak tidur'), findsOneWidget);
    expect(find.text('بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا'), findsOneWidget);
    expect(find.text('Bismika Allahumma amutu wa ahya.'), findsOneWidget);
    expect(
      find.text('Dengan nama-Mu, ya Allah, aku mati dan aku hidup.'),
      findsOneWidget,
    );
    expect(find.text('Sahih al-Bukhari 6314'), findsOneWidget);

    final arabic = tester.widget<SelectableText>(
      find.byKey(const ValueKey('reader-arabic')),
    );
    expect(arabic.textDirection, TextDirection.rtl);
    expect(arabic.style?.fontSize, 32);

    await tester.tap(find.byTooltip('Tampilan bacaan'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('reader-transliteration-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-translation-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Bismika Allahumma amutu wa ahya.'), findsNothing);
    expect(
      find.text('Dengan nama-Mu, ya Allah, aku mati dan aku hidup.'),
      findsNothing,
    );
    expect(find.text('بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا'), findsOneWidget);

    await tester.tap(find.byTooltip('Tampilan bacaan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-scale-115')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SelectableText>(find.byKey(const ValueKey('reader-arabic')))
          .style
          ?.fontSize,
      closeTo(36.8, 0.01),
    );
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
  });

  testWidgets('unknown or mismatched content is unavailable and safe', (
    tester,
  ) async {
    final harness = _ReaderRouterHarness(
      initialLocation: '/routines/sholat-malam/reader/not-found',
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byType(ReaderUnavailableScreen), findsOneWidget);
    expect(find.text('Bacaan tidak tersedia'), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);
    expect(tester.takeException(), isNull);

    harness.router.go('/routines/zuhur/reader/doa-sebelum-tidur');
    await tester.pumpAndSettle();
    expect(find.byType(ReaderUnavailableScreen), findsOneWidget);
  });

  testWidgets('Reader builds with light and dark themes at compact width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final harness = _ReaderRouterHarness(
        initialLocation: '/routines/sholat-malam/reader/doa-sebelum-tidur',
        themeMode: mode,
      );
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
    }
  });
}

class _ReaderRouterHarness {
  _ReaderRouterHarness({
    required String initialLocation,
    this.themeMode = ThemeMode.system,
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
    locale: const Locale('id'),
    supportedLocales: const [Locale('id'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
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
