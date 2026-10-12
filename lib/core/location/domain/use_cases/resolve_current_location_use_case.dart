import '../models/location_access_status.dart';
import '../models/location_unavailable_exception.dart';
import '../models/resolved_location.dart';
import '../repositories/location_repository.dart';

class ResolveCurrentLocationUseCase {
  const ResolveCurrentLocationUseCase({required this.locationRepository});

  final LocationRepository locationRepository;

  Future<LocationAccessStatus> checkAccess() =>
      locationRepository.checkAccess();

  Future<LocationAccessStatus> requestAccess() =>
      locationRepository.requestAccess();

  Future<bool> openAppSettings() => locationRepository.openAppSettings();

  Future<bool> openLocationSettings() =>
      locationRepository.openLocationSettings();

  Future<ResolvedLocation> call() async {
    try {
      return ResolvedLocation(
        coordinate: await locationRepository.getCurrentLocation(),
        usedLastKnownLocation: false,
      );
    } catch (_) {
      try {
        final lastKnown = await locationRepository.getLastKnownLocation();
        if (lastKnown != null) {
          return ResolvedLocation(
            coordinate: lastKnown,
            usedLastKnownLocation: true,
          );
        }
      } catch (_) {
        // Expose one provider-neutral failure after both attempts.
      }
      throw const LocationUnavailableException();
    }
  }
}
