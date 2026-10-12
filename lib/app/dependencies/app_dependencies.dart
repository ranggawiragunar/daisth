import 'package:http/http.dart' as http;

import '../../core/location/data/repositories/location_repository_data.dart';
import '../../core/location/domain/repositories/location_repository.dart';
import '../../core/location/domain/use_cases/resolve_current_location_use_case.dart';
import '../../core/maps/services/map_navigation_service.dart';
import '../../features/prayer_times/data/mappers/prayer_time_mapper.dart';
import '../../features/prayer_times/data/repositories/prayer_time_repository_data.dart';
import '../../features/prayer_times/data/services/prayer_time_adhan_service.dart';
import '../../features/prayer_times/domain/repositories/prayer_time_repository.dart';
import '../../features/prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';
import '../../features/prayer_times/presentation/prayer_schedule_session.dart';
import '../../features/mosque/data/mappers/mosque_mapper.dart';
import '../../features/mosque/data/repositories/mosque_repository_data.dart';
import '../../features/mosque/data/services/mosque_overpass_service.dart';
import '../../features/mosque/domain/repositories/mosque_repository.dart';
import '../../features/mosque/domain/use_cases/find_nearby_mosques_use_case.dart';

class AppDependencies {
  AppDependencies({
    http.Client? httpClient,
    LocationRepository? locationRepository,
    MosqueRepository? mosqueRepository,
    MapNavigationService? mapNavigationService,
    PrayerTimeRepository? prayerTimeRepository,
    this.startTodayClock = true,
  }) : httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null {
    this.locationRepository = locationRepository ?? LocationRepositoryData();
    this.mosqueRepository =
        mosqueRepository ??
        MosqueRepositoryData(
          service: MosqueOverpassService(client: this.httpClient),
          mapper: MosqueMapper(),
        );
    this.mapNavigationService = mapNavigationService ?? MapNavigationService();
    resolveCurrentLocation = ResolveCurrentLocationUseCase(
      locationRepository: this.locationRepository,
    );
    this.prayerTimeRepository =
        prayerTimeRepository ??
        PrayerTimeRepositoryData(
          service: PrayerTimeAdhanService(),
          mapper: PrayerTimeMapper(),
        );
    loadTodayPrayerSchedule = LoadTodayPrayerScheduleUseCase(
      resolveCurrentLocation: resolveCurrentLocation,
      prayerTimeRepository: this.prayerTimeRepository,
    );
    prayerScheduleSession = PrayerScheduleSession(loadTodayPrayerSchedule);
    nearbyMosques = FindNearbyMosquesUseCase(
      locationRepository: this.locationRepository,
      mosqueRepository: this.mosqueRepository,
      resolveCurrentLocation: resolveCurrentLocation,
    );
  }

  final http.Client httpClient;
  final bool startTodayClock;
  final bool _ownsHttpClient;
  late final LocationRepository locationRepository;
  late final ResolveCurrentLocationUseCase resolveCurrentLocation;
  late final PrayerTimeRepository prayerTimeRepository;
  late final LoadTodayPrayerScheduleUseCase loadTodayPrayerSchedule;
  late final PrayerScheduleSession prayerScheduleSession;
  late final MosqueRepository mosqueRepository;
  late final MapNavigationService mapNavigationService;
  late final FindNearbyMosquesUseCase nearbyMosques;

  void dispose() {
    prayerScheduleSession.dispose();
    if (_ownsHttpClient) httpClient.close();
  }
}
