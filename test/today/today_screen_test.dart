import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';
import 'package:daisth/core/location/domain/use_cases/resolve_current_location_use_case.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:daisth/features/prayer_times/domain/repositories/prayer_time_repository.dart';
import 'package:daisth/features/prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';
import 'package:daisth/features/prayer_times/presentation/prayer_schedule_session.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/routines/domain/models/routine_status.dart';
import 'package:daisth/features/routines/data/catalog/default_routine_template_catalog.dart';
import 'package:daisth/features/routines/domain/models/routine_schedule.dart';
import 'package:daisth/features/today/presentation/widgets/routine_timeline.dart';
import 'package:daisth/features/today/presentation/view_models/today_view_model.dart';
import '../support/test_persistence.dart';
import 'package:daisth/features/today/presentation/today_screen.dart';

void main() {
  test('Today loads stored status for today and ignores yesterday', () async {
    final store = await TestPersistence.create();
    addTearDown(store.dispose);
    final today = CalendarDay.fromDateTime(DateTime.now());
    final yesterday = CalendarDay.fromDateTime(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    await store.routineRecords.markCompleted(
      routine: RoutineDemoData.zuhur,
      day: today,
      now: DateTime.now().toUtc(),
    );
    await store.routineRecords.setStepCompletion(
      routine: RoutineDemoData.sholatMalam,
      day: today,
      stepId: 'hajat',
      isCompleted: true,
      now: DateTime.now().toUtc(),
    );
    await store.routineRecords.markCompleted(
      routine: RoutineDemoData.dhuha,
      day: yesterday,
      now: DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    final location = _Location(access: LocationAccessStatus.denied);
    final session = _session(location);
    addTearDown(session.dispose);
    final viewModel = TodayViewModel(
      prayerScheduleSession: session,
      routineRecordRepository: store.routineRecords,
      startClock: false,
    );
    addTearDown(viewModel.dispose);
    await viewModel.initialize();
    expect(viewModel.recordedStatuses['zuhur'], RoutineStatus.completed);
    expect(viewModel.recordedStatuses['sholat-malam'], RoutineStatus.partial);
    expect(viewModel.recordedStatuses.containsKey('dhuha'), isFalse);
    expect(
      (await store.routineRecords.getRoutineRecord(yesterday, 'dhuha'))?.status,
      RoutineStatus.completed,
    );
  });

  testWidgets('Today asks inline without requesting permission on launch', (
    tester,
  ) async {
    final location = _Location(access: LocationAccessStatus.denied);
    final session = _session(location);
    addTearDown(session.dispose);
    await _pumpToday(tester, session);

    expect(find.text('Set up prayer times'), findsOneWidget);
    expect(find.text('Use my location'), findsOneWidget);
    expect(location.requestCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today renders calculated times and opens mandatory rows', (
    tester,
  ) async {
    final location = _Location();
    final repository = _PrayerRepository();
    final session = _session(location, repository);
    addTearDown(session.dispose);
    final opened = <String>[];
    await _pumpToday(tester, session, onRoutineTap: opened.add);

    expect(find.text('04:16'), findsWidgets);
    expect(find.text('11:41'), findsWidgets);
    expect(find.text('14:42'), findsWidgets);
    expect(find.text('17:46'), findsWidgets);
    expect(find.text('18:56'), findsWidgets);
    for (final id in ['subuh', 'zuhur', 'asar', 'maghrib', 'isya']) {
      final row = find.byKey(ValueKey('today-routine-$id'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pump();
    }
    expect(opened, ['subuh', 'zuhur', 'asar', 'maghrib', 'isya']);
    expect(repository.calls, 1);
  });

  testWidgets('Penutup Hari uses its saved time and opens from Today', (
    tester,
  ) async {
    final date = DateTime(2026, 10, 13);
    final schedule = PrayerDaySchedule(
      date: date,
      coordinate: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
      fajr: DateTime(2026, 10, 13, 4, 16),
      sunrise: DateTime(2026, 10, 13, 5, 30),
      dhuhr: DateTime(2026, 10, 13, 11, 41),
      asr: DateTime(2026, 10, 13, 14, 42),
      maghrib: DateTime(2026, 10, 13, 17, 46),
      isha: DateTime(2026, 10, 13, 18, 56),
      calculationSettings: PrayerCalculationSettings.defaultSettings,
    );
    final definition =
        DefaultRoutineTemplateCatalog.definitions(DateTime.utc(2026, 10, 1))
            .singleWhere((item) => item.id == 'penutup-hari')
            .copyWith(schedule: const FixedRoutineSchedule(22 * 60 + 15));
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: RoutineTimeline(
              schedule: schedule,
              period: null,
              definitions: [definition],
              onRoutineTap: opened.add,
            ),
          ),
        ),
      ),
    );

    final row = find.byKey(const ValueKey('today-routine-penutup-hari'));
    expect(find.text('22:15'), findsOneWidget);
    await tester.ensureVisible(row);
    await tester.tap(row);
    expect(opened, ['penutup-hari']);
  });

  testWidgets('Today labels last-known location and refreshes on request', (
    tester,
  ) async {
    final location = _Location(
      currentError: StateError('no current fix'),
      lastKnown: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
    );
    final repository = _PrayerRepository();
    final session = _session(location, repository);
    addTearDown(session.dispose);
    await _pumpToday(tester, session);

    expect(find.text('Using your last known location.'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('Using your last known location.'), findsOneWidget);
  });
}

Future<void> _pumpToday(
  WidgetTester tester,
  PrayerScheduleSession session, {
  ValueChanged<String>? onRoutineTap,
}) async {
  final persistence = await tester.runAsync(TestPersistence.create);
  if (persistence == null) throw StateError('Test database did not open.');
  addTearDown(persistence.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: DaisthTheme.light,
      darkTheme: DaisthTheme.dark,
      home: TodayScreen(
        prayerScheduleSession: session,
        routineRecordRepository: persistence.routineRecords,
        startClock: false,
        onRoutineTap: onRoutineTap,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

PrayerScheduleSession _session(
  _Location location, [
  _PrayerRepository? repository,
]) => PrayerScheduleSession(
  LoadTodayPrayerScheduleUseCase(
    resolveCurrentLocation: ResolveCurrentLocationUseCase(
      locationRepository: location,
    ),
    prayerTimeRepository: repository ?? _PrayerRepository(),
  ),
);

class _Location implements LocationRepository {
  _Location({
    this.access = LocationAccessStatus.granted,
    this.currentError,
    this.lastKnown,
  });

  final LocationAccessStatus access;
  final Object? currentError;
  final GeoCoordinate? lastKnown;
  int requestCount = 0;

  @override
  Future<LocationAccessStatus> checkAccess() async => access;
  @override
  Future<LocationAccessStatus> requestAccess() async {
    requestCount++;
    return access;
  }

  @override
  Future<GeoCoordinate> getCurrentLocation() async {
    if (currentError != null) throw currentError!;
    return const GeoCoordinate(latitude: -6.2, longitude: 106.8);
  }

  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => lastKnown;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}

class _PrayerRepository implements PrayerTimeRepository {
  int calls = 0;

  @override
  Future<PrayerDaySchedule> calculateSchedule({
    required GeoCoordinate coordinate,
    required DateTime date,
    PrayerCalculationSettings settings =
        PrayerCalculationSettings.defaultSettings,
  }) async {
    calls++;
    final day = DateTime(date.year, date.month, date.day);
    return PrayerDaySchedule(
      date: day,
      coordinate: coordinate,
      fajr: day.add(const Duration(hours: 4, minutes: 16)),
      sunrise: day.add(const Duration(hours: 5, minutes: 30)),
      dhuhr: day.add(const Duration(hours: 11, minutes: 41)),
      asr: day.add(const Duration(hours: 14, minutes: 42)),
      maghrib: day.add(const Duration(hours: 17, minutes: 46)),
      isha: day.add(const Duration(hours: 18, minutes: 56)),
      calculationSettings: settings,
    );
  }
}
