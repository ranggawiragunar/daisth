import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../../../../core/location/domain/models/location_access_status.dart';
import '../../../../core/location/domain/repositories/location_repository.dart';
import '../models/mosque_search_failure.dart';
import '../models/nearby_mosque_result.dart';
import '../models/mosque_place.dart';
import '../repositories/mosque_repository.dart';

class FindNearbyMosquesUseCase {
  FindNearbyMosquesUseCase({
    required this.locationRepository,
    required this.mosqueRepository,
  });

  static const searchRadiiMeters = [1500, 3000, 5000];
  static const minimumUsefulResults = 6;
  static const maximumResults = 20;

  final LocationRepository locationRepository;
  final MosqueRepository mosqueRepository;

  Future<LocationAccessStatus> checkLocationAccess() =>
      locationRepository.checkAccess();

  Future<LocationAccessStatus> requestLocationAccess() =>
      locationRepository.requestAccess();

  Future<bool> openAppSettings() => locationRepository.openAppSettings();

  Future<bool> openLocationSettings() =>
      locationRepository.openLocationSettings();

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
      usedLastKnownLocation: location.usedLastKnown,
    );
  }

  Future<({GeoCoordinate coordinate, bool usedLastKnown})>
  _resolveLocation() async {
    try {
      return (
        coordinate: await locationRepository.getCurrentLocation(),
        usedLastKnown: false,
      );
    } catch (_) {
      try {
        final lastKnown = await locationRepository.getLastKnownLocation();
        if (lastKnown != null) {
          return (coordinate: lastKnown, usedLastKnown: true);
        }
      } catch (_) {
        // The domain error below intentionally hides plugin-specific details.
      }
      throw const LocationUnavailableFailure();
    }
  }
}
