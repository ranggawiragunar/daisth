import 'prayer_day_schedule.dart';

class LoadedPrayerSchedule {
  const LoadedPrayerSchedule({
    required this.schedule,
    required this.usedLastKnownLocation,
  });

  final PrayerDaySchedule schedule;
  final bool usedLastKnownLocation;
}
