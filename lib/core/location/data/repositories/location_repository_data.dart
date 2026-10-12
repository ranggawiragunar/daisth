import 'package:geolocator/geolocator.dart';

import '../../domain/models/geo_coordinate.dart';
import '../../domain/models/location_access_status.dart';
import '../../domain/repositories/location_repository.dart';
import '../services/location_geolocator_service.dart';

class LocationRepositoryData implements LocationRepository {
  LocationRepositoryData({LocationGeolocatorService? service})
    : _service = service ?? LocationGeolocatorService();

  final LocationGeolocatorService _service;

  @override
  Future<LocationAccessStatus> checkAccess() async {
    if (!await _service.isLocationServiceEnabled()) {
      return LocationAccessStatus.serviceDisabled;
    }
    return _mapPermission(await _service.checkPermission());
  }

  @override
  Future<LocationAccessStatus> requestAccess() async {
    if (!await _service.isLocationServiceEnabled()) {
      return LocationAccessStatus.serviceDisabled;
    }
    return _mapPermission(await _service.requestPermission());
  }

  @override
  Future<GeoCoordinate> getCurrentLocation() async =>
      _toCoordinate(await _service.getCurrentPosition());

  @override
  Future<GeoCoordinate?> getLastKnownLocation() async {
    final position = await _service.getLastKnownPosition();
    return position == null ? null : _toCoordinate(position);
  }

  @override
  Future<bool> openAppSettings() => _service.openAppSettings();

  @override
  Future<bool> openLocationSettings() => _service.openLocationSettings();

  LocationAccessStatus _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.whileInUse ||
        LocationPermission.always => LocationAccessStatus.granted,
        LocationPermission.deniedForever => LocationAccessStatus.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationAccessStatus.denied,
      };

  GeoCoordinate _toCoordinate(Position position) =>
      GeoCoordinate(latitude: position.latitude, longitude: position.longitude);
}
