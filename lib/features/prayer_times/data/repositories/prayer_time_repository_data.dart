import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../../domain/models/prayer_calculation_settings.dart';
import '../../domain/models/prayer_day_schedule.dart';
import '../../domain/repositories/prayer_time_repository.dart';
import '../mappers/prayer_time_mapper.dart';
import '../services/prayer_time_adhan_service.dart';

class PrayerTimeRepositoryData implements PrayerTimeRepository {
  const PrayerTimeRepositoryData({required this.service, required this.mapper});

  final PrayerTimeAdhanService service;
  final PrayerTimeMapper mapper;

  @override
  Future<PrayerDaySchedule> calculateSchedule({
    required GeoCoordinate coordinate,
    required DateTime date,
    PrayerCalculationSettings settings =
        PrayerCalculationSettings.defaultSettings,
  }) async => mapper.map(
    service.calculate(coordinate: coordinate, date: date, settings: settings),
  );
}
