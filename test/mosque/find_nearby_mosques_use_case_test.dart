import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/core/location/domain/models/location_access_status.dart';
import 'package:istiqam/core/location/domain/repositories/location_repository.dart';
import 'package:istiqam/features/mosque/domain/models/mosque_place.dart';
import 'package:istiqam/features/mosque/domain/models/mosque_place_type.dart';
import 'package:istiqam/features/mosque/domain/repositories/mosque_repository.dart';
import 'package:istiqam/features/mosque/domain/use_cases/find_nearby_mosques_use_case.dart';

void main() {
  const origin = GeoCoordinate(latitude: -6.2, longitude: 106.8);

  test(
    'expands radii until six results and caps sorted output at twenty',
    () async {
      final location = _LocationRepository(current: origin);
      final mosque = _MosqueRepository({
        1500: [_place('a', 420), _place('b', 150)],
        3000: [_place('c', 700), _place('d', 600)],
        5000: List.generate(
          25,
          (index) => _place('more-$index', 300.0 + index),
        ),
      });
      final useCase = FindNearbyMosquesUseCase(
        locationRepository: location,
        mosqueRepository: mosque,
      );

      final result = await useCase();

      expect(mosque.radii, [1500, 3000, 5000]);
      expect(result.searchedRadiusMeters, 5000);
      expect(result.places, hasLength(20));
      expect(result.places.first.id, 'b');
      expect(result.places.first.distanceMeters, 150);
    },
  );

  test('stops early once six places are found', () async {
    final mosque = _MosqueRepository({
      1500: List.generate(6, (index) => _place('$index', index.toDouble())),
    });
    final result = await FindNearbyMosquesUseCase(
      locationRepository: _LocationRepository(current: origin),
      mosqueRepository: mosque,
    )();
    expect(mosque.radii, [1500]);
    expect(result.searchedRadiusMeters, 1500);
  });

  test('uses last known coordinate only as explicit fallback', () async {
    final lastKnown = const GeoCoordinate(latitude: -6.3, longitude: 106.9);
    final result = await FindNearbyMosquesUseCase(
      locationRepository: _LocationRepository(
        currentError: StateError('no fix'),
        lastKnown: lastKnown,
      ),
      mosqueRepository: _MosqueRepository(const {}),
    )();
    expect(result.origin, lastKnown);
    expect(result.usedLastKnownLocation, isTrue);
  });
}

MosquePlace _place(String id, double distance) => MosquePlace(
  id: id,
  name: id,
  coordinate: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
  distanceMeters: distance,
  type: MosquePlaceType.mosque,
);

class _MosqueRepository implements MosqueRepository {
  _MosqueRepository(this.placesByRadius);

  final Map<int, List<MosquePlace>> placesByRadius;
  final radii = <int>[];

  @override
  Future<List<MosquePlace>> findNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
  }) async {
    radii.add(radiusMeters);
    return placesByRadius[radiusMeters] ?? const [];
  }
}

class _LocationRepository implements LocationRepository {
  _LocationRepository({this.current, this.currentError, this.lastKnown});

  final GeoCoordinate? current;
  final Object? currentError;
  final GeoCoordinate? lastKnown;

  @override
  Future<LocationAccessStatus> checkAccess() async =>
      LocationAccessStatus.granted;
  @override
  Future<GeoCoordinate> getCurrentLocation() async {
    if (currentError != null) throw currentError!;
    return current!;
  }

  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => lastKnown;
  @override
  Future<LocationAccessStatus> requestAccess() async =>
      LocationAccessStatus.granted;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}
