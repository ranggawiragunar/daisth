import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/core/location/domain/models/location_unavailable_exception.dart';
import 'package:istiqam/core/location/domain/models/location_access_status.dart';
import 'package:istiqam/core/location/domain/repositories/location_repository.dart';
import 'package:istiqam/core/location/domain/use_cases/resolve_current_location_use_case.dart';

void main() {
  const current = GeoCoordinate(latitude: -6.2, longitude: 106.8);
  const stale = GeoCoordinate(latitude: -6.3, longitude: 106.9);

  test(
    'returns fresh current location without reading last-known value',
    () async {
      final repository = _Location(current: current, lastKnown: stale);

      final result = await ResolveCurrentLocationUseCase(
        locationRepository: repository,
      )();

      expect(result.coordinate, current);
      expect(result.usedLastKnownLocation, isFalse);
      expect(repository.lastKnownReadCount, 0);
    },
  );

  test('uses last-known location only after current location fails', () async {
    final repository = _Location(
      currentError: StateError('no fresh fix'),
      lastKnown: stale,
    );

    final result = await ResolveCurrentLocationUseCase(
      locationRepository: repository,
    )();

    expect(result.coordinate, stale);
    expect(result.usedLastKnownLocation, isTrue);
    expect(repository.lastKnownReadCount, 1);
  });

  test(
    'reports unavailable when neither current nor last-known is usable',
    () async {
      final resolver = ResolveCurrentLocationUseCase(
        locationRepository: _Location(currentError: StateError('no fix')),
      );
      await expectLater(
        resolver(),
        throwsA(isA<LocationUnavailableException>()),
      );
    },
  );
}

class _Location implements LocationRepository {
  _Location({this.current, this.currentError, this.lastKnown});

  final GeoCoordinate? current;
  final Object? currentError;
  final GeoCoordinate? lastKnown;
  int lastKnownReadCount = 0;

  @override
  Future<LocationAccessStatus> checkAccess() async =>
      LocationAccessStatus.granted;
  @override
  Future<GeoCoordinate> getCurrentLocation() async {
    if (currentError != null) throw currentError!;
    return current!;
  }

  @override
  Future<GeoCoordinate?> getLastKnownLocation() async {
    lastKnownReadCount++;
    return lastKnown;
  }

  @override
  Future<LocationAccessStatus> requestAccess() async =>
      LocationAccessStatus.granted;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}
