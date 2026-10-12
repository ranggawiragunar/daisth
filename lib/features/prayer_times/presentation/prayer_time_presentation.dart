import '../domain/models/prayer_name.dart';

abstract final class PrayerTimePresentation {
  static const mandatoryPrayers = [
    PrayerName.fajr,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
  ];

  static String label(PrayerName prayer) => switch (prayer) {
    PrayerName.fajr => 'Subuh',
    PrayerName.sunrise => 'Terbit',
    PrayerName.dhuhr => 'Zuhur',
    PrayerName.asr => 'Asar',
    PrayerName.maghrib => 'Maghrib',
    PrayerName.isha => 'Isya',
  };

  static String time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static String routineId(PrayerName prayer) => switch (prayer) {
    PrayerName.fajr => 'subuh',
    PrayerName.dhuhr => 'zuhur',
    PrayerName.asr => 'asar',
    PrayerName.maghrib => 'maghrib',
    PrayerName.isha => 'isya',
    PrayerName.sunrise => 'dhuha',
  };

  static String date(DateTime value) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]}';
  }
}
