import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:daisth/app/app_preferences_scope.dart';
import 'package:daisth/app/dependencies/app_dependencies.dart';
import 'package:daisth/app/router/app_router.dart';
import 'package:daisth/app/router/route_paths.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/features/routines/presentation/routine_detail_screen.dart';
import 'package:daisth/features/mosque/presentation/screens/mosque_finder_screen.dart';
import 'package:daisth/features/routines/domain/models/routine_definition.dart';
import 'package:daisth/features/routines/domain/models/routine_origin.dart';
import 'package:daisth/features/routines/domain/models/routine_priority.dart';
import 'package:daisth/features/routines/domain/models/routine_schedule.dart';
import 'package:daisth/features/routines/data/catalog/default_routine_template_catalog.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/reader/presentation/screens/reader_screen.dart';

import '../support/fake_routine_repository.dart';
import '../support/fake_routine_record_repository.dart';
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

  testWidgets(
    'History day opens an editable historical routine and clear restores Unrecorded',
    (tester) async {
      final records = FakeRoutineRecordRepository();
      final definitions = FakeRoutineRepository(
        definitions: DefaultRoutineTemplateCatalog.definitions(
          DateTime.utc(2026, 10, 1),
        ),
      );
      final harness = _RouterHarness(
        initialLocation: '/history/2026-10-12',
        dependencies: AppDependencies(
          locationRepository: _DeniedLocation(),
          databaseService: TestPersistence.createDatabaseService(),
          routineRepository: definitions,
          routineRecordRepository: records,
          startTodayClock: false,
        ),
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();
      expect(find.text('Unrecorded'), findsNWidgets(5));

      await tester.tap(find.text('Sholat Zuhur'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Editing'), findsOneWidget);
      await tester.tap(find.text('Mark Zuhur Done'));
      await tester.pumpAndSettle();
      final selectedDay = CalendarDay(year: 2026, month: 10, day: 12);
      expect(await records.getRoutineRecord(selectedDay, 'zuhur'), isNotNull);
      expect(
        await records.getRoutineRecord(
          CalendarDay.fromDateTime(DateTime.now()),
          'zuhur',
        ),
        isNull,
      );

      await tester.tap(find.text('Clear record'));
      await tester.pumpAndSettle();
      expect(find.text('This day will return to Unrecorded.'), findsOneWidget);
      await tester.tap(find.text('Clear record').last);
      await tester.pumpAndSettle();
      expect(await records.getRoutineRecord(selectedDay, 'zuhur'), isNull);
    },
  );

  testWidgets('historical Penutup Hari Reader returns to its selected date', (
    tester,
  ) async {
    final day = CalendarDay.fromDateTime(DateTime.now()).addDays(-1);
    final records = FakeRoutineRecordRepository();
    final definitions = FakeRoutineRepository(
      definitions: DefaultRoutineTemplateCatalog.definitions(
        DateTime.now().subtract(const Duration(days: 40)),
      ),
    );
    await records.markCompleted(
      routine: RoutineDemoData.penutupHari,
      day: day,
      now: DateTime.now().toUtc(),
    );
    final harness = _RouterHarness(
      initialLocation: RoutePaths.historyDay(day.toDateKey()),
      dependencies: AppDependencies(
        locationRepository: _DeniedLocation(),
        databaseService: TestPersistence.createDatabaseService(),
        routineRepository: definitions,
        routineRecordRepository: records,
        startTodayClock: false,
      ),
    );
    addTearDown(records.close);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    final bedtimeEntry = find.ancestor(
      of: find.text('Penutup Hari'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(bedtimeEntry.last);
    await tester.tap(bedtimeEntry.last);
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Ayat Kursi'));
    await tester.tap(find.text('Ayat Kursi').last);
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    final reader = tester.widget<ReaderScreen>(find.byType(ReaderScreen));
    expect(
      reader.fallbackRoute,
      RoutePaths.historyRoutine(day.toDateKey(), 'penutup-hari'),
    );

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailScreen), findsOneWidget);
    expect(find.textContaining('Editing'), findsOneWidget);
  });

  testWidgets('malformed history date is a safe route', (tester) async {
    final harness = _RouterHarness(initialLocation: '/history/foo');
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    expect(find.text('Tanggal history tidak valid.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('History list renders neutral daily summaries and opens a day', (
    tester,
  ) async {
    final day = CalendarDay.fromDateTime(DateTime.now()).addDays(-1);
    final records = FakeRoutineRecordRepository();
    final definitions = FakeRoutineRepository(
      definitions: DefaultRoutineTemplateCatalog.definitions(
        DateTime.now().subtract(const Duration(days: 40)),
      ),
    );
    for (final routine in [
      RoutineDemoData.subuh,
      RoutineDemoData.zuhur,
      RoutineDemoData.asar,
      RoutineDemoData.maghrib,
      RoutineDemoData.isya,
    ]) {
      await records.markCompleted(
        routine: routine,
        day: day,
        now: DateTime.now(),
      );
    }
    final harness = _RouterHarness(
      initialLocation: RoutePaths.history,
      dependencies: AppDependencies(
        locationRepository: _DeniedLocation(),
        databaseService: TestPersistence.createDatabaseService(),
        routineRepository: definitions,
        routineRecordRepository: records,
        startTodayClock: false,
      ),
    );
    addTearDown(records.close);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('5 completed'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);

    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();
    expect(find.text('Day Detail'), findsOneWidget);
    expect(find.text('Completed'), findsNWidgets(5));
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

  testWidgets('stable custom routine IDs resolve through Routine Detail', (
    tester,
  ) async {
    final created = DateTime.utc(2026, 10, 13);
    final custom = RoutineDefinition(
      id: 'custom-stable-route',
      origin: RoutineOrigin.custom,
      title: 'Morning Reading',
      description: null,
      isEnabled: true,
      isArchived: false,
      schedule: RoutineSchedule.fixed(6 * 60 + 30),
      reminderEnabled: true,
      priority: RoutinePriority.medium,
      sortOrder: 100,
      createdAt: created,
      updatedAt: created,
    );
    final harness = _RouterHarness(
      initialLocation: '/routines/${custom.id}',
      dependencies: AppDependencies(
        locationRepository: _DeniedLocation(),
        databaseService: TestPersistence.createDatabaseService(),
        routineRepository: FakeRoutineRepository(definitions: [custom]),
        routineRecordRepository: FakeRoutineRecordRepository(),
        startTodayClock: false,
      ),
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RoutineDetailScreen), findsOneWidget);
    expect(find.text('Morning Reading'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Nearby Mosque opens the finder before completion outside shell',
    (tester) async {
      final harness = _RouterHarness(
        initialLocation: '/routines/zuhur',
        dependencies: AppDependencies(
          locationRepository: _DeniedLocation(),
          databaseService: TestPersistence.createDatabaseService(),
          routineRepository: FakeRoutineRepository(),
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
             routineRepository: FakeRoutineRepository(),
             startTodayClock: false,
           ) {
    router = createAppRouter(
      noticeController: noticeController,
      dependencies: this.dependencies,
      initialLocation: initialLocation,
    );
  }

  final noticeController = DaisthNoticeController();
  final AppDependencies dependencies;
  late final GoRouter router;

  Widget get app => MaterialApp.router(
    theme: DaisthTheme.light,
    darkTheme: DaisthTheme.dark,
    routerConfig: router,
    builder: (context, child) => AppPreferencesScope(
      themeMode: ThemeMode.system,
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
