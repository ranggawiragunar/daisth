import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:istiqam/app/app_preferences_scope.dart';
import 'package:istiqam/app/router/app_router.dart';
import 'package:istiqam/core/design_system/components/istiqam_notice_controller.dart';
import 'package:istiqam/core/design_system/theme/istiqam_theme.dart';
import 'package:istiqam/features/reader/presentation/screens/reader_screen.dart';

void main() {
  testWidgets('Reader opens from Routine Detail and back preserves it', (
    tester,
  ) async {
    final harness = _ReaderRouterHarness(
      initialLocation: '/routines/sholat-malam',
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Partial · 2 of 4'), findsOneWidget);

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
    expect(find.text('Partial · 2 of 4'), findsOneWidget);
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
