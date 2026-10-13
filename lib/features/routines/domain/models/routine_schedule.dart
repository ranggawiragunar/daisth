import 'prayer_key.dart';

sealed class RoutineSchedule {
  const RoutineSchedule();

  String get kind;
  int? get minutesAfterMidnight => null;
  PrayerKey? get prayerKey => null;

  factory RoutineSchedule.fixed(int minutesAfterMidnight) {
    if (minutesAfterMidnight < 0 || minutesAfterMidnight >= 24 * 60) {
      throw ArgumentError.value(minutesAfterMidnight, 'minutesAfterMidnight');
    }
    return FixedRoutineSchedule(minutesAfterMidnight);
  }

  factory RoutineSchedule.prayer(PrayerKey key) => PrayerRoutineSchedule(key);
}

final class FixedRoutineSchedule extends RoutineSchedule {
  const FixedRoutineSchedule(this.value);
  final int value;

  @override
  String get kind => 'fixed';
  @override
  int get minutesAfterMidnight => value;
}

final class PrayerRoutineSchedule extends RoutineSchedule {
  const PrayerRoutineSchedule(this.value);
  final PrayerKey value;

  @override
  String get kind => 'prayer';
  @override
  PrayerKey get prayerKey => value;
}
