import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/core/location/domain/models/location_access_exception.dart';
import 'package:istiqam/core/location/domain/models/location_access_status.dart';
import 'package:istiqam/core/location/domain/models/location_unavailable_exception.dart';
import 'package:istiqam/core/location/domain/repositories/location_repository.dart';
import 'package:istiqam/core/location/domain/use_cases/resolve_current_location_use_case.dart';
import 'package:istiqam/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:istiqam/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:istiqam/features/prayer_times/domain/repositories/prayer_time_repository.dart';
import 'package:istiqam/features/prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';

void main() {
  const coordinate = GeoCoordinate(latitude: -6.2, longitude: 106.8);
  final date = DateTime(2026, 10, 10, 12);

  test('calculates schedule using fresh foreground location', () async {
    final location = _Location(current: coordinate);
    final prayerRepository = _PrayerRepository();
    final useCase = _useCase(location, prayerRepository);

    final result = await useCase(date: date);

    expect(result.usedLastKnownLocation, isFalse);
    expect(result.schedule.coordinate, coordinate);
    expect(result.schedule.date, DateTime(2026, 10, 10));
    expect(prayerRepository.date, date);
    expect(
      prayerRepository.settings,
      PrayerCalculationSettings.defaultSettings,
    );
  });

  test('preserves last-known location indicator', () async {
    final location = _Location(
      currentError: StateError('no fresh position'),
      lastKnown: coordinate,
    );

    final result = await _useCase(location, _PrayerRepository())(date: date);

    expect(result.usedLastKnownLocation, isTrue);
    expect(result.schedule.coordinate, coordinate);
  });

  test('propagates denied permission without attempting location', () async {
    final location = _Location(access: LocationAccessStatus.denied);
    final prayerRepository = _PrayerRepository();

    await expectLater(
      _useCase(location, prayerRepository)(date: date),
      throwsA(
        isA<LocationAccessException>().having(
          (error) => error.status,
          'status',
          LocationAccessStatus.denied,
        ),
      ),
    );
    expect(location.currentReadCount, 0);
    expect(prayerRepository.callCount, 0);
  });

  test('propagates disabled location service distinctly', () async {
    final location = _Location(access: LocationAccessStatus.serviceDisabled);

    await expectLater(
      _useCase(location, _PrayerRepository())(date: date),
      throwsA(
        isA<LocationAccessException>().having(
          (error) => error.status,
          'status',
          LocationAccessStatus.serviceDisabled,
        ),
      ),
    );
  });

  test(
    'propagates location unavailable when fresh and last-known fail',
    () async {
      final location = _Location(currentError: StateError('no fix'));
      await expectLater(
        _useCase(location, _PrayerRepository())(date: date),
        throwsA(isA<LocationUnavailableException>()),
      );
    },
  );
}

LoadTodayPrayerScheduleUseCase _useCase(
  _Location location,
  _PrayerRepository prayerRepository,
) => LoadTodayPrayerScheduleUseCase(
  resolveCurrentLocation: ResolveCurrentLocationUseCase(
    locationRepository: location,
  ),
  prayerTimeRepository: prayerRepository,
);

class _Location implements LocationRepository {
  _Location({
    this.access = LocationAccessStatus.granted,
    this.current,
    this.currentError,
    this.lastKnown,
  });

  final LocationAccessStatus access;
  final GeoCoordinate? current;
  final Object? currentError;
  final GeoCoordinate? lastKnown;
  int currentReadCount = 0;

  @override
  Future<LocationAccessStatus> checkAccess() async => access;
  @override
  Future<LocationAccessStatus> requestAccess() async => access;
  @override
  Future<GeoCoordinate> getCurrentLocation() async {
    currentReadCount++;
    if (currentError != null) throw currentError!;
    return current!;
  }

  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => lastKnown;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}

class _PrayerRepository implements PrayerTimeRepository {
  int callCount = 0;
  GeoCoordinate? coordinate;
  DateTime? date;
  PrayerCalculationSettings? settings;

  @override
  Future<PrayerDaySchedule> calculateSchedule({
    required GeoCoordinate coordinate,
    required DateTime date,
    PrayerCalculationSettings settings =
        PrayerCalculationSettings.defaultSettings,
  }) async {
    callCount++;
    this.coordinate = coordinate;
    this.date = date;
    this.settings = settings;
    final day = DateTime(date.year, date.month, date.day);
    return PrayerDaySchedule(
      date: day,
      coordinate: coordinate,
      fajr: day.add(const Duration(hours: 4)),
      sunrise: day.add(const Duration(hours: 5)),
      dhuhr: day.add(const Duration(hours: 12)),
      asr: day.add(const Duration(hours: 15)),
      maghrib: day.add(const Duration(hours: 18)),
      isha: day.add(const Duration(hours: 19)),
      calculationSettings: settings,
    );
  }
}
