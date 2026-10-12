import 'package:adhan_dart/adhan_dart.dart' as adhan;

import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../../domain/models/prayer_calculation_settings.dart';
import '../models/prayer_day_schedule_data.dart';

class PrayerTimeAdhanService {
  PrayerDayScheduleData calculate({
    required GeoCoordinate coordinate,
    required DateTime date,
    required PrayerCalculationSettings settings,
  }) {
    final adhanCoordinates = adhan.Coordinates(
      coordinate.latitude,
      coordinate.longitude,
    );
    final parameters = switch (settings.method) {
      PrayerCalculationMethod.indonesiaKemenag =>
        adhan.CalculationMethodParameters.indonesian(),
    };
    parameters
      ..madhab = switch (settings.asrMethod) {
        PrayerAsrMethod.shafi => adhan.Madhab.shafi,
        PrayerAsrMethod.hanafi => adhan.Madhab.hanafi,
      }
      ..highLatitudeRule = adhan.HighLatitudeRule.recommended(adhanCoordinates);

    final day = DateTime(date.year, date.month, date.day);
    final prayerTimes = adhan.PrayerTimes(
      coordinates: adhanCoordinates,
      date: day,
      calculationParameters: parameters,
    );
    return PrayerDayScheduleData(
      date: day,
      coordinate: coordinate,
      fajr: prayerTimes.fajr.toLocal(),
      sunrise: prayerTimes.sunrise.toLocal(),
      dhuhr: prayerTimes.dhuhr.toLocal(),
      asr: prayerTimes.asr.toLocal(),
      maghrib: prayerTimes.maghrib.toLocal(),
      isha: prayerTimes.isha.toLocal(),
      calculationSettings: settings,
    );
  }
}
