import '../models/prayer_day_schedule.dart';
import '../models/prayer_name.dart';
import '../models/prayer_period_state.dart';

class ResolveCurrentPrayerPeriodUseCase {
  const ResolveCurrentPrayerPeriodUseCase();

  PrayerPeriodState call({
    required PrayerDaySchedule schedule,
    required DateTime now,
  }) {
    final prayers = [
      (PrayerName.fajr, schedule.fajr),
      (PrayerName.dhuhr, schedule.dhuhr),
      (PrayerName.asr, schedule.asr),
      (PrayerName.maghrib, schedule.maghrib),
      (PrayerName.isha, schedule.isha),
    ];

    if (now.isBefore(schedule.fajr)) {
      return const PrayerPeriodState(
        currentPrayer: null,
        nextPrayer: PrayerName.fajr,
      );
    }
    if (now.isBefore(schedule.sunrise)) {
      return const PrayerPeriodState(
        currentPrayer: PrayerName.fajr,
        nextPrayer: PrayerName.dhuhr,
      );
    }

    for (var index = 1; index < prayers.length; index++) {
      final (prayer, time) = prayers[index];
      if (now.isBefore(time)) {
        final previousPrayer = prayers[index - 1].$1;
        final current = previousPrayer == PrayerName.fajr
            ? null
            : previousPrayer;
        return PrayerPeriodState(currentPrayer: current, nextPrayer: prayer);
      }
    }

    return const PrayerPeriodState(
      currentPrayer: PrayerName.isha,
      nextPrayer: null,
    );
  }
}
