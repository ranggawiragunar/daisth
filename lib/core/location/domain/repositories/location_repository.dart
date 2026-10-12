import '../models/geo_coordinate.dart';
import '../models/location_access_status.dart';

abstract interface class LocationRepository {
  Future<LocationAccessStatus> checkAccess();

  Future<LocationAccessStatus> requestAccess();

  Future<GeoCoordinate> getCurrentLocation();

  Future<GeoCoordinate?> getLastKnownLocation();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}
