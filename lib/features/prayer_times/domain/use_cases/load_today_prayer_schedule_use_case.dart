import '../../../../core/location/domain/models/location_access_status.dart';
import '../../../../core/location/domain/models/location_access_exception.dart';
import '../../../../core/location/domain/models/resolved_location.dart';
import '../../../../core/location/domain/use_cases/resolve_current_location_use_case.dart';
import '../models/loaded_prayer_schedule.dart';
import '../models/prayer_calculation_settings.dart';
import '../repositories/prayer_time_repository.dart';

class LoadTodayPrayerScheduleUseCase {
  const LoadTodayPrayerScheduleUseCase({
    required this.resolveCurrentLocation,
    required this.prayerTimeRepository,
    this.defaultSettings = PrayerCalculationSettings.defaultSettings,
  });

  final ResolveCurrentLocationUseCase resolveCurrentLocation;
  final PrayerTimeRepository prayerTimeRepository;
  final PrayerCalculationSettings defaultSettings;

  Future<LocationAccessStatus> checkLocationAccess() =>
      resolveCurrentLocation.checkAccess();

  Future<LocationAccessStatus> requestLocationAccess() =>
      resolveCurrentLocation.requestAccess();

  Future<bool> openAppSettings() => resolveCurrentLocation.openAppSettings();

  Future<bool> openLocationSettings() =>
      resolveCurrentLocation.openLocationSettings();

  Future<LoadedPrayerSchedule> call({DateTime? date}) async {
    final access = await checkLocationAccess();
    if (access != LocationAccessStatus.granted) {
      throw LocationAccessException(access);
    }
    final ResolvedLocation location = await resolveCurrentLocation();
    final schedule = await prayerTimeRepository.calculateSchedule(
      coordinate: location.coordinate,
      date: date ?? DateTime.now(),
      settings: defaultSettings,
    );
    return LoadedPrayerSchedule(
      schedule: schedule,
      usedLastKnownLocation: location.usedLastKnownLocation,
    );
  }
}
