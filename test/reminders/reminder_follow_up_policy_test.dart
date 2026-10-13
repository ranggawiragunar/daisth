import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:daisth/features/reminders/domain/use_cases/reminder_follow_up_policy.dart';

void main() {
  const policy = ReminderFollowUpPolicy();
  final schedule = PrayerDaySchedule(
    date: DateTime(2026, 10, 13),
    coordinate: const GeoCoordinate(latitude: -6, longitude: 106),
    fajr: DateTime(2026, 10, 13, 5),
    sunrise: DateTime(2026, 10, 13, 6),
    dhuhr: DateTime(2026, 10, 13, 12),
    asr: DateTime(2026, 10, 13, 15, 30),
    maghrib: DateTime(2026, 10, 13, 18),
    isha: DateTime(2026, 10, 13, 19),
    calculationSettings: PrayerCalculationSettings.defaultSettings,
  );
  test('uses prayer window end and minimum gap', () {
    final now = DateTime(2026, 10, 13, 11);
    expect(
      policy.scheduleAt(
        routineId: 'zuhur',
        primaryAt: DateTime(2026, 10, 13, 11, 50),
        prayerSchedule: schedule,
        now: now,
      ),
      DateTime(2026, 10, 13, 14, 30),
    );
    expect(
      policy.scheduleAt(
        routineId: 'asar',
        primaryAt: DateTime(2026, 10, 13, 15, 20),
        prayerSchedule: schedule,
        now: now,
      ),
      DateTime(2026, 10, 13, 17),
    );
    expect(
      policy.scheduleAt(
        routineId: 'maghrib',
        primaryAt: DateTime(2026, 10, 13, 17, 36),
        prayerSchedule: schedule,
        now: now,
      ),
      DateTime(2026, 10, 13, 18, 21),
    );
  });
  test('uses one hour fallback, skips past times and reference routines', () {
    expect(
      policy.scheduleAt(
        routineId: 'subuh',
        primaryAt: DateTime(2026, 10, 13, 4),
        prayerSchedule: schedule,
        now: DateTime(2026, 10, 13, 4, 30),
      ),
      DateTime(2026, 10, 13, 5),
    );
    expect(
      policy.scheduleAt(
        routineId: 'dhuha',
        primaryAt: DateTime(2026, 10, 13, 7),
        prayerSchedule: schedule,
        now: DateTime(2026, 10, 13, 6),
      ),
      DateTime(2026, 10, 13, 8),
    );
    expect(
      policy.scheduleAt(
        routineId: 'penutup-hari',
        primaryAt: DateTime(2026, 10, 13, 21),
        prayerSchedule: schedule,
        now: DateTime(2026, 10, 13, 20),
      ),
      DateTime(2026, 10, 13, 22),
    );
    expect(
      policy.scheduleAt(
        routineId: 'penutup-hari',
        primaryAt: DateTime(2026, 10, 13, 22, 15),
        prayerSchedule: schedule,
        now: DateTime(2026, 10, 13, 22),
      ),
      DateTime(2026, 10, 13, 23, 15),
    );
    expect(
      policy.scheduleAt(
        routineId: 'reflection',
        primaryAt: DateTime(2026, 10, 13, 20),
        prayerSchedule: schedule,
        now: DateTime(2026, 10, 13, 19),
      ),
      isNull,
    );
    expect(
      policy.scheduleAt(
        routineId: 'isya',
        primaryAt: DateTime(2026, 10, 13, 20),
        prayerSchedule: schedule,
        now: DateTime(2026, 10, 13, 21),
      ),
      isNull,
    );
  });
}
