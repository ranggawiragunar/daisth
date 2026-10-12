import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:istiqam/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:istiqam/features/prayer_times/domain/models/prayer_name.dart';
import 'package:istiqam/features/prayer_times/domain/use_cases/resolve_current_prayer_period_use_case.dart';

void main() {
  const resolver = ResolveCurrentPrayerPeriodUseCase();
  final schedule = PrayerDaySchedule(
    date: DateTime(2026, 10, 10),
    coordinate: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
    fajr: DateTime(2026, 10, 10, 4, 18),
    sunrise: DateTime(2026, 10, 10, 5, 30),
    dhuhr: DateTime(2026, 10, 10, 11, 43),
    asr: DateTime(2026, 10, 10, 14, 44),
    maghrib: DateTime(2026, 10, 10, 17, 49),
    isha: DateTime(2026, 10, 10, 18, 58),
    calculationSettings: PrayerCalculationSettings.defaultSettings,
  );

  test('before Fajr shows Subuh as upcoming', () {
    final state = resolver(
      schedule: schedule,
      now: DateTime(2026, 10, 10, 4, 0),
    );
    expect(state.currentPrayer, isNull);
    expect(state.nextPrayer, PrayerName.fajr);
    expect(state.focusPrayer, PrayerName.fajr);
    expect(state.focusLabel, 'Berikutnya');
  });

  test('during Fajr window focuses Subuh', () {
    final state = resolver(
      schedule: schedule,
      now: DateTime(2026, 10, 10, 4, 30),
    );
    expect(state.currentPrayer, PrayerName.fajr);
    expect(state.nextPrayer, PrayerName.dhuhr);
    expect(state.focusLabel, 'Waktunya');
  });

  test('after Sunrise before Dhuhr shows Dhuhr next', () {
    final state = resolver(schedule: schedule, now: DateTime(2026, 10, 10, 8));
    expect(state.currentPrayer, isNull);
    expect(state.nextPrayer, PrayerName.dhuhr);
  });

  test('between Dhuhr and Asr focuses Dhuhr', () {
    expect(
      resolver(schedule: schedule, now: DateTime(2026, 10, 10, 13)).focusPrayer,
      PrayerName.dhuhr,
    );
  });

  test('between Asr and Maghrib focuses Asr', () {
    expect(
      resolver(schedule: schedule, now: DateTime(2026, 10, 10, 16)).focusPrayer,
      PrayerName.asr,
    );
  });

  test('between Maghrib and Isha focuses Maghrib', () {
    expect(
      resolver(schedule: schedule, now: DateTime(2026, 10, 10, 18)).focusPrayer,
      PrayerName.maghrib,
    );
  });

  test('after Isha keeps Isya focused until date rolls over', () {
    expect(
      resolver(schedule: schedule, now: DateTime(2026, 10, 10, 23)).focusPrayer,
      PrayerName.isha,
    );
  });

  test('after midnight today schedule makes next Subuh upcoming', () {
    final tomorrow = PrayerDaySchedule(
      date: DateTime(2026, 10, 11),
      coordinate: schedule.coordinate,
      fajr: DateTime(2026, 10, 11, 4, 18),
      sunrise: DateTime(2026, 10, 11, 5, 30),
      dhuhr: DateTime(2026, 10, 11, 11, 43),
      asr: DateTime(2026, 10, 11, 14, 44),
      maghrib: DateTime(2026, 10, 11, 17, 49),
      isha: DateTime(2026, 10, 11, 18, 58),
      calculationSettings: schedule.calculationSettings,
    );
    final state = resolver(schedule: tomorrow, now: DateTime(2026, 10, 11, 1));
    expect(state.currentPrayer, isNull);
    expect(state.nextPrayer, PrayerName.fajr);
  });
}
