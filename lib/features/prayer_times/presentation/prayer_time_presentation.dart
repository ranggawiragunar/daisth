import 'package:flutter/widgets.dart';

import '../../../core/localization/daisth_terminology.dart';
import '../domain/models/prayer_name.dart';

abstract final class PrayerTimePresentation {
  static const mandatoryPrayers = [
    PrayerName.fajr,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
  ];

  static String label(PrayerName prayer, Locale locale) => switch (prayer) {
    PrayerName.fajr => DaisthTerminology.prayerName('subuh', locale),
    PrayerName.sunrise => locale.languageCode == 'id' ? 'Terbit' : 'Sunrise',
    PrayerName.dhuhr => DaisthTerminology.prayerName('zuhur', locale),
    PrayerName.asr => DaisthTerminology.prayerName('asar', locale),
    PrayerName.maghrib => DaisthTerminology.prayerName('maghrib', locale),
    PrayerName.isha => DaisthTerminology.prayerName('isya', locale),
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
