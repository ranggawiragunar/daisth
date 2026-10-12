import '../../../../core/location/domain/models/location_access_status.dart';
import '../../../../core/location/domain/models/location_unavailable_exception.dart';
import '../../../../core/location/domain/models/resolved_location.dart';
import '../../../../core/location/domain/repositories/location_repository.dart';
import '../../../../core/location/domain/use_cases/resolve_current_location_use_case.dart';
import '../models/mosque_search_failure.dart';
import '../models/nearby_mosque_result.dart';
import '../models/mosque_place.dart';
import '../repositories/mosque_repository.dart';

class FindNearbyMosquesUseCase {
  FindNearbyMosquesUseCase({
    required LocationRepository locationRepository,
    required this.mosqueRepository,
    ResolveCurrentLocationUseCase? resolveCurrentLocation,
  }) : resolveCurrentLocation =
           resolveCurrentLocation ??
           ResolveCurrentLocationUseCase(
             locationRepository: locationRepository,
           );

  static const searchRadiiMeters = [1500, 3000, 5000];
  static const minimumUsefulResults = 6;
  static const maximumResults = 20;

  final MosqueRepository mosqueRepository;
  final ResolveCurrentLocationUseCase resolveCurrentLocation;

  Future<LocationAccessStatus> checkLocationAccess() =>
      resolveCurrentLocation.checkAccess();

  Future<LocationAccessStatus> requestLocationAccess() =>
      resolveCurrentLocation.requestAccess();

  Future<bool> openAppSettings() => resolveCurrentLocation.openAppSettings();

  Future<bool> openLocationSettings() =>
      resolveCurrentLocation.openLocationSettings();

  Future<NearbyMosqueResult> call() async {
    final location = await _resolveLocation();
    final placesById = <String, MosquePlace>{};
    var searchedRadius = searchRadiiMeters.first;

    for (final radius in searchRadiiMeters) {
      searchedRadius = radius;
      final found = await mosqueRepository.findNearby(
        origin: location.coordinate,
        radiusMeters: radius,
      );
      for (final place in found) {
        placesById.putIfAbsent(place.id, () => place);
      }
      if (placesById.length >= minimumUsefulResults) break;
    }

    final places = placesById.values.toList()
      ..sort(
        (first, second) =>
            first.distanceMeters.compareTo(second.distanceMeters),
      );
    return NearbyMosqueResult(
      origin: location.coordinate,
      places: places.take(maximumResults).toList(),
      searchedRadiusMeters: searchedRadius,
      usedLastKnownLocation: location.usedLastKnownLocation,
    );
  }

  Future<ResolvedLocation> _resolveLocation() async {
    try {
      return await resolveCurrentLocation();
    } on LocationUnavailableException {
      throw const LocationUnavailableFailure();
    }
  }
}
