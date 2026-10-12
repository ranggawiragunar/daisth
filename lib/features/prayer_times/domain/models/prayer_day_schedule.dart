import '../../../../core/location/domain/models/geo_coordinate.dart';
import 'prayer_calculation_settings.dart';
import 'prayer_name.dart';
import 'prayer_time_entry.dart';

class PrayerDaySchedule {
  const PrayerDaySchedule({
    required this.date,
    required this.coordinate,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.calculationSettings,
  });

  final DateTime date;
  final GeoCoordinate coordinate;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final PrayerCalculationSettings calculationSettings;

  List<PrayerTimeEntry> get entries => [
    PrayerTimeEntry(prayer: PrayerName.fajr, time: fajr),
    PrayerTimeEntry(prayer: PrayerName.sunrise, time: sunrise),
    PrayerTimeEntry(prayer: PrayerName.dhuhr, time: dhuhr),
    PrayerTimeEntry(prayer: PrayerName.asr, time: asr),
    PrayerTimeEntry(prayer: PrayerName.maghrib, time: maghrib),
    PrayerTimeEntry(prayer: PrayerName.isha, time: isha),
  ];

  DateTime timeFor(PrayerName prayer) => switch (prayer) {
    PrayerName.fajr => fajr,
    PrayerName.sunrise => sunrise,
    PrayerName.dhuhr => dhuhr,
    PrayerName.asr => asr,
    PrayerName.maghrib => maghrib,
    PrayerName.isha => isha,
  };
}
