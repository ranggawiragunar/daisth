import 'location_access_status.dart';

class LocationAccessException implements Exception {
  const LocationAccessException(this.status);

  final LocationAccessStatus status;
}
