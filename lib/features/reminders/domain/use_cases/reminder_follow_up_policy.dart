import '../../../prayer_times/domain/models/prayer_day_schedule.dart';

class ReminderFollowUpPolicy {
  const ReminderFollowUpPolicy();
  static const supportedRoutineIds = {
    'sholat-malam',
    'subuh',
    'dhuha',
    'zuhur',
    'asar',
    'maghrib',
    'isya',
  };

  DateTime? scheduleAt({
    required String routineId,
    required DateTime primaryAt,
    required PrayerDaySchedule prayerSchedule,
    required DateTime now,
  }) {
    if (!supportedRoutineIds.contains(routineId) &&
        !routineId.startsWith('custom-')) {
      return null;
    }
    final DateTime? windowEnd = switch (routineId) {
      'zuhur' => prayerSchedule.asr,
      'asar' => prayerSchedule.maghrib,
      'maghrib' => prayerSchedule.isha,
      _ => null,
    };
    final candidate = windowEnd == null
        ? primaryAt.add(const Duration(hours: 1))
        : _later(
            windowEnd.subtract(const Duration(hours: 1)),
            primaryAt.add(const Duration(minutes: 45)),
          );
    if (windowEnd != null && !candidate.isBefore(windowEnd)) return null;
    return candidate.isAfter(now) ? candidate : null;
  }

  DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
}
