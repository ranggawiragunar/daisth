import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/features/prayer_times/data/services/prayer_time_adhan_service.dart';
import 'package:istiqam/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:istiqam/features/prayer_times/domain/models/prayer_name.dart';

void main() {
  final service = PrayerTimeAdhanService();
  const jakarta = GeoCoordinate(latitude: -6.2, longitude: 106.8166);

  test('calculates all six entries in solar order for arbitrary dates', () {
    final schedule = service.calculate(
      coordinate: jakarta,
      date: DateTime(2026, 10, 10),
      settings: PrayerCalculationSettings.defaultSettings,
    );

    expect(schedule.date, DateTime(2026, 10, 10));
    expect(
      schedule.calculationSettings.method,
      PrayerCalculationMethod.indonesiaKemenag,
    );
    expect(schedule.calculationSettings.asrMethod, PrayerAsrMethod.shafi);
    expect(schedule.fajr.isBefore(schedule.sunrise), isTrue);
    expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue);
    expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
    expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
    expect(schedule.maghrib.isBefore(schedule.isha), isTrue);
  });

  test('Shafi Asr calculation is earlier than Hanafi', () {
    final shafi = service.calculate(
      coordinate: jakarta,
      date: DateTime(2026, 10, 10),
      settings: PrayerCalculationSettings.defaultSettings,
    );
    final hanafi = service.calculate(
      coordinate: jakarta,
      date: DateTime(2026, 10, 10),
      settings: const PrayerCalculationSettings(
        asrMethod: PrayerAsrMethod.hanafi,
      ),
    );

    expect(shafi.asr.isBefore(hanafi.asr), isTrue);
  });

  test(
    'Jakarta KEMENAG schedule stays within the documented five-minute range',
    () {
      final schedule = service.calculate(
        coordinate: jakarta,
        date: DateTime(2026, 10, 10),
        settings: PrayerCalculationSettings.defaultSettings,
      );
      const benchmark = {
        PrayerName.fajr: 4 * 60 + 18,
        PrayerName.dhuhr: 11 * 60 + 43,
        PrayerName.asr: 14 * 60 + 44,
        PrayerName.maghrib: 17 * 60 + 49,
        PrayerName.isha: 18 * 60 + 58,
      };
      final actual = {
        PrayerName.fajr: schedule.fajr,
        PrayerName.dhuhr: schedule.dhuhr,
        PrayerName.asr: schedule.asr,
        PrayerName.maghrib: schedule.maghrib,
        PrayerName.isha: schedule.isha,
      };
      for (final entry in benchmark.entries) {
        final minutes =
            actual[entry.key]!.hour * 60 + actual[entry.key]!.minute;
        expect(
          (minutes - entry.value).abs(),
          lessThanOrEqualTo(5),
          reason: '${entry.key.name}: actual ${actual[entry.key]}',
        );
      }
    },
  );

  test('recommended high-latitude rule keeps northern travel calculable', () {
    final schedule = service.calculate(
      coordinate: const GeoCoordinate(latitude: 59.9139, longitude: 10.7522),
      date: DateTime(2026, 6, 21),
      settings: PrayerCalculationSettings.defaultSettings,
    );

    expect(schedule.fajr.isBefore(schedule.sunrise), isTrue);
    expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue);
    expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
    expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
    expect(schedule.maghrib.isBefore(schedule.isha), isTrue);
  });
}
