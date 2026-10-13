import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/features/prayer_times/data/mappers/prayer_time_mapper.dart';
import 'package:daisth/features/prayer_times/data/models/prayer_day_schedule_data.dart';
import 'package:daisth/features/prayer_times/data/repositories/prayer_time_repository_data.dart';
import 'package:daisth/features/prayer_times/data/services/prayer_time_adhan_service.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_day_schedule.dart';

void main() {
  test('repository maps service data into a domain schedule', () async {
    final repository = PrayerTimeRepositoryData(
      service: _FakeAdhanService(),
      mapper: PrayerTimeMapper(),
    );

    final result = await repository.calculateSchedule(
      coordinate: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
      date: DateTime(2026, 10, 10),
      settings: PrayerCalculationSettings.defaultSettings,
    );

    expect(result, isA<PrayerDaySchedule>());
    expect(result, isNot(isA<PrayerDayScheduleData>()));
    expect(result.fajr, DateTime(2026, 10, 10, 4, 18));
  });
}

class _FakeAdhanService implements PrayerTimeAdhanService {
  @override
  PrayerDayScheduleData calculate({
    required GeoCoordinate coordinate,
    required DateTime date,
    required PrayerCalculationSettings settings,
  }) => PrayerDayScheduleData(
    date: DateTime(date.year, date.month, date.day),
    coordinate: coordinate,
    fajr: DateTime(date.year, date.month, date.day, 4, 18),
    sunrise: DateTime(date.year, date.month, date.day, 5, 30),
    dhuhr: DateTime(date.year, date.month, date.day, 11, 43),
    asr: DateTime(date.year, date.month, date.day, 14, 44),
    maghrib: DateTime(date.year, date.month, date.day, 17, 49),
    isha: DateTime(date.year, date.month, date.day, 18, 58),
    calculationSettings: settings,
  );
}
