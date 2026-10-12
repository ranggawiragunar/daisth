import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/core/location/domain/models/location_access_status.dart';
import 'package:istiqam/core/location/domain/repositories/location_repository.dart';
import 'package:istiqam/features/mosque/domain/models/mosque_place.dart';
import 'package:istiqam/features/mosque/domain/models/mosque_place_type.dart';
import 'package:istiqam/features/mosque/domain/repositories/mosque_repository.dart';
import 'package:istiqam/features/mosque/domain/use_cases/find_nearby_mosques_use_case.dart';

void main() {
  test(
    'requests one 5 km dataset and chooses 1.5 km locally when sufficient',
    () async {
      final mosque = _MosqueRepository([
        ...List.generate(6, (index) => _place('near-$index', 100 + index * 50)),
        _place('outside-effective-radius', 2000),
      ]);
      final result = await _useCase(mosque)();

      expect(mosque.requests, [5000]);
      expect(result.searchedRadiusMeters, 1500);
      expect(result.places, hasLength(6));
      expect(
        result.places.map((place) => place.id),
        isNot(contains('outside-effective-radius')),
      );
    },
  );

  test(
    'chooses 3 km when only that local radius has six usable results',
    () async {
      final mosque = _MosqueRepository([
        ...List.generate(
          5,
          (index) => _place('near-$index', 100 + index * 100),
        ),
        _place('middle-1', 1800),
        _place('middle-2', 1900),
        _place('middle-3', 2000),
        _place('middle-4', 2100),
        _place('middle-5', 2200),
        _place('middle-6', 2300),
        _place('outside-effective-radius', 4000),
      ]);
      final result = await _useCase(mosque)();

      expect(mosque.requests, [5000]);
      expect(result.searchedRadiusMeters, 3000);
      expect(result.places, hasLength(11));
      expect(result.places.last.distanceMeters, 2300);
    },
  );

  test(
    'uses 5 km when fewer than six results exist within 3 km and caps at twenty',
    () async {
      final mosque = _MosqueRepository([
        ...List.generate(
          2,
          (index) => _place('near-$index', 100 + index * 100),
        ),
        ...List.generate(
          25,
          (index) => _place('far-$index', 3200 + index * 20),
        ),
      ]);
      final result = await _useCase(mosque)();

      expect(mosque.requests, [5000]);
      expect(result.searchedRadiusMeters, 5000);
      expect(result.places, hasLength(20));
      expect(result.places.first.id, 'near-0');
    },
  );

  test(
    'deduplicates by provider identity before local radius selection',
    () async {
      final mosque = _MosqueRepository([
        ...List.generate(
          5,
          (index) => _place('near-$index', 100 + index * 100),
        ),
        _place('duplicate', 500),
        _place('duplicate', 2000),
      ]);
      final result = await _useCase(mosque)();

      expect(result.searchedRadiusMeters, 1500);
      expect(
        result.places.where((place) => place.id == 'duplicate'),
        hasLength(1),
      );
    },
  );

  test('forwards explicit refresh to bypass repository cache', () async {
    final mosque = _MosqueRepository(const []);
    await _useCase(mosque)(forceRefresh: true);
    expect(mosque.bypassCacheCalls, [true]);
  });

  test('uses last known coordinate only as explicit fallback', () async {
    final lastKnown = const GeoCoordinate(latitude: -6.3, longitude: 106.9);
    final result = await FindNearbyMosquesUseCase(
      locationRepository: _LocationRepository(
        currentError: StateError('no fix'),
        lastKnown: lastKnown,
      ),
      mosqueRepository: _MosqueRepository(const []),
    )();
    expect(result.origin, lastKnown);
    expect(result.usedLastKnownLocation, isTrue);
  });
}

FindNearbyMosquesUseCase _useCase(_MosqueRepository mosque) =>
    FindNearbyMosquesUseCase(
      locationRepository: _LocationRepository(
        current: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
      ),
      mosqueRepository: mosque,
    );

MosquePlace _place(String id, double distance) => MosquePlace(
  id: id,
  name: id,
  coordinate: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
  distanceMeters: distance,
  type: MosquePlaceType.mosque,
);

class _MosqueRepository implements MosqueRepository {
  _MosqueRepository(this.places);

  final List<MosquePlace> places;
  final requests = <int>[];
  final bypassCacheCalls = <bool>[];

  @override
  Future<List<MosquePlace>> findNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
    bool bypassCache = false,
  }) async {
    requests.add(radiusMeters);
    bypassCacheCalls.add(bypassCache);
    return places;
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
