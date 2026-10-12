import 'package:http/http.dart' as http;

import '../../core/location/data/repositories/location_repository_data.dart';
import '../../core/location/domain/repositories/location_repository.dart';
import '../../core/maps/services/map_navigation_service.dart';
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
    nearbyMosques = FindNearbyMosquesUseCase(
      locationRepository: this.locationRepository,
      mosqueRepository: this.mosqueRepository,
    );
  }

  final http.Client httpClient;
  final bool _ownsHttpClient;
  late final LocationRepository locationRepository;
  late final MosqueRepository mosqueRepository;
  late final MapNavigationService mapNavigationService;
  late final FindNearbyMosquesUseCase nearbyMosques;

  void dispose() {
    if (_ownsHttpClient) httpClient.close();
  }
}
