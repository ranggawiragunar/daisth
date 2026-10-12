import '../../domain/models/prayer_day_schedule.dart';
import '../models/prayer_day_schedule_data.dart';

class PrayerTimeMapper {
  PrayerDaySchedule map(PrayerDayScheduleData data) => PrayerDaySchedule(
    date: data.date,
    coordinate: data.coordinate,
    fajr: data.fajr,
    sunrise: data.sunrise,
    dhuhr: data.dhuhr,
    asr: data.asr,
    maghrib: data.maghrib,
    isha: data.isha,
    calculationSettings: data.calculationSettings,
  );
}
