import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/core/location/domain/models/location_access_status.dart';
import 'package:istiqam/core/location/domain/repositories/location_repository.dart';
import 'package:istiqam/core/location/domain/use_cases/resolve_current_location_use_case.dart';
import 'package:istiqam/core/design_system/theme/istiqam_theme.dart';
import 'package:istiqam/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:istiqam/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:istiqam/features/prayer_times/domain/repositories/prayer_time_repository.dart';
import 'package:istiqam/features/prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';
import 'package:istiqam/features/prayer_times/presentation/prayer_schedule_session.dart';
import 'package:istiqam/features/today/presentation/today_screen.dart';

void main() {
  testWidgets('Today asks inline without requesting permission on launch', (
    tester,
  ) async {
    final location = _Location(access: LocationAccessStatus.denied);
    final session = _session(location);
    addTearDown(session.dispose);
    await _pumpToday(tester, session);

    expect(find.text('Aktifkan jadwal sholat'), findsOneWidget);
    expect(find.text('Gunakan lokasi saya'), findsOneWidget);
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

    expect(find.text('04:16'), findsOneWidget);
    expect(find.text('11:41'), findsOneWidget);
    expect(find.text('14:42'), findsOneWidget);
    expect(find.text('17:46'), findsOneWidget);
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

    expect(find.text('Menggunakan lokasi terakhir.'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('Menggunakan lokasi terakhir.'), findsOneWidget);
  });
}

Future<void> _pumpToday(
  WidgetTester tester,
  PrayerScheduleSession session, {
  ValueChanged<String>? onRoutineTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: IstiqamTheme.light,
      darkTheme: IstiqamTheme.dark,
      home: TodayScreen(
        prayerScheduleSession: session,
        startClock: false,
        onRoutineTap: onRoutineTap,
      ),
    ),
  );
  await tester.pumpAndSettle();
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
