import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../models/prayer_calculation_settings.dart';
import '../models/prayer_day_schedule.dart';

abstract interface class PrayerTimeRepository {
  Future<PrayerDaySchedule> calculateSchedule({
    required GeoCoordinate coordinate,
    required DateTime date,
    PrayerCalculationSettings settings,
  });
}
