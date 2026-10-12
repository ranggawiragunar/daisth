import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:istiqam/app/app_preferences_scope.dart';
import 'package:istiqam/app/router/app_router.dart';
import 'package:istiqam/app/router/route_paths.dart';
import 'package:istiqam/core/design_system/components/istiqam_notice_controller.dart';
import 'package:istiqam/core/design_system/theme/istiqam_theme.dart';
import 'package:istiqam/features/routines/presentation/routine_detail_screen.dart';

void main() {
  testWidgets('root redirects to Today', (tester) async {
    final harness = _RouterHarness(initialLocation: RoutePaths.root);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text("Assalamu'alaikum"), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsOneWidget);
  });

  testWidgets('stable Routine Detail paths resolve outside the shell', (
    tester,
  ) async {
    final harness = _RouterHarness(initialLocation: '/routines/dhuha');
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    expect(find.text('Belum dimulai'), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);

    harness.router.go('/routines/sholat-malam');
    await tester.pumpAndSettle();
    expect(find.text('Partial · 2 of 4'), findsOneWidget);
    expect(find.byType(RoutineDetailScreen), findsOneWidget);

    harness.router.go('/routines/zuhur');
    await tester.pumpAndSettle();
    expect(find.text('Due now'), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-settings')), findsNothing);
  });

  testWidgets('unknown routine is safe and offers a working return action', (
    tester,
  ) async {
    final harness = _RouterHarness(initialLocation: '/routines/not-found');
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byType(RoutineUnavailableScreen), findsOneWidget);
    expect(find.text('Routine tidak tersedia'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text("Assalamu'alaikum"), findsOneWidget);
  });

  testWidgets('system back pops a Routine Detail route to Today', (
    tester,
  ) async {
    final harness = _RouterHarness(initialLocation: RoutePaths.today);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Open Routine'));
    await tester.tap(find.text('Open Routine'));
    await tester.pumpAndSettle();
    expect(find.text('Due now'), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);
    expect(harness.router.canPop(), isTrue);

    final wasHandled = await tester.binding.handlePopRoute();
    expect(wasHandled, isTrue);
    await tester.pumpAndSettle();
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      RoutePaths.today,
    );
    expect(find.byKey(const ValueKey('navigation-today')), findsOneWidget);

    await tester.ensureVisible(find.text('Sholat Dhuha'));
    await tester.tap(find.text('Sholat Dhuha'));
    await tester.pumpAndSettle();
    expect(find.text('Belum dimulai'), findsOneWidget);
    expect(harness.router.canPop(), isTrue);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      RoutePaths.today,
    );
    expect(find.byKey(const ValueKey('navigation-today')), findsOneWidget);
  });
}

class _RouterHarness {
  _RouterHarness({required String initialLocation}) {
    router = createAppRouter(
      noticeController: noticeController,
      initialLocation: initialLocation,
    );
  }

  final noticeController = IstiqamNoticeController();
  late final GoRouter router;

  Widget get app => MaterialApp.router(
    theme: IstiqamTheme.light,
    darkTheme: IstiqamTheme.dark,
    routerConfig: router,
    builder: (context, child) => AppPreferencesScope(
      themeMode: ThemeMode.system,
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
