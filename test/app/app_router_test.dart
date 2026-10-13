import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:istiqam/app/app_preferences_scope.dart';
import 'package:istiqam/app/dependencies/app_dependencies.dart';
import 'package:istiqam/app/router/app_router.dart';
import 'package:istiqam/app/router/route_paths.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/core/location/domain/models/location_access_status.dart';
import 'package:istiqam/core/location/domain/repositories/location_repository.dart';
import 'package:istiqam/core/design_system/components/istiqam_notice_controller.dart';
import 'package:istiqam/core/design_system/theme/istiqam_theme.dart';
import 'package:istiqam/features/routines/presentation/routine_detail_screen.dart';
import 'package:istiqam/features/mosque/presentation/screens/mosque_finder_screen.dart';

import '../support/test_persistence.dart';

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
    expect(find.text('Belum dimulai'), findsOneWidget);
    expect(find.byType(RoutineDetailScreen), findsOneWidget);

    harness.router.go('/routines/zuhur');
    await tester.pumpAndSettle();
    expect(find.text('Belum dimulai'), findsOneWidget);
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

  testWidgets(
    'Nearby Mosque opens the finder before completion outside shell',
    (tester) async {
      final harness = _RouterHarness(
        initialLocation: '/routines/zuhur',
        dependencies: AppDependencies(
          locationRepository: _DeniedLocation(),
          databaseService: TestPersistence.createDatabaseService(),
          startTodayClock: false,
        ),
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Nearby Mosque'));
      await tester.tap(
        find.byKey(const ValueKey('routine-link-Nearby Mosque')),
      );
      await tester.pumpAndSettle();

      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/routines/zuhur/mosques',
      );
      expect(find.byType(MosqueFinderScreen), findsOneWidget);
      expect(find.text('Temukan tempat sholat di dekatmu'), findsOneWidget);
      expect(find.byKey(const ValueKey('navigation-today')), findsNothing);
    },
  );

  testWidgets('system back pops a Routine Detail route to Today', (
    tester,
  ) async {
    final harness = _RouterHarness(initialLocation: RoutePaths.today);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    final zuhurRow = find.byKey(const ValueKey('today-routine-zuhur'));
    await Scrollable.ensureVisible(tester.element(zuhurRow), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(zuhurRow);
    await tester.pumpAndSettle();
    expect(find.text('Belum dimulai'), findsOneWidget);
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

    final dhuhaRow = find.byKey(const ValueKey('today-routine-dhuha'));
    await Scrollable.ensureVisible(tester.element(dhuhaRow), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(dhuhaRow);
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
  _RouterHarness({
    required String initialLocation,
    AppDependencies? dependencies,
  }) : dependencies =
           dependencies ??
           AppDependencies(
             locationRepository: _DeniedLocation(),
             databaseService: TestPersistence.createDatabaseService(),
             startTodayClock: false,
           ) {
    router = createAppRouter(
      noticeController: noticeController,
      dependencies: this.dependencies,
      initialLocation: initialLocation,
    );
  }

  final noticeController = IstiqamNoticeController();
  final AppDependencies dependencies;
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
    dependencies.dispose();
    noticeController.dispose();
  }
}

class _DeniedLocation implements LocationRepository {
  @override
  Future<LocationAccessStatus> checkAccess() async =>
      LocationAccessStatus.denied;
  @override
  Future<GeoCoordinate> getCurrentLocation() async =>
      throw StateError('permission denied');
  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => null;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
  @override
  Future<LocationAccessStatus> requestAccess() async =>
      LocationAccessStatus.denied;
}
