import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../../domain/models/prayer_calculation_settings.dart';

class PrayerDayScheduleData {
  const PrayerDayScheduleData({
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
}
