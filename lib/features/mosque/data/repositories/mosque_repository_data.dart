import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../../domain/models/mosque_place.dart';
import '../../domain/models/mosque_search_failure.dart';
import '../../domain/repositories/mosque_repository.dart';
import '../mappers/mosque_mapper.dart';
import '../models/mosque_place_data.dart';
import '../services/mosque_overpass_service.dart';

class MosqueRepositoryData implements MosqueRepository {
  MosqueRepositoryData({
    required this.service,
    required this.mapper,
    DateTime Function()? clock,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _clock = clock ?? DateTime.now;

  static const coordinateBucketScale = 1000;

  final MosqueOverpassService service;
  final MosqueMapper mapper;
  final DateTime Function() _clock;
  final Duration cacheTtl;
  final Map<String, _CachedPlaces> _cache = {};

  @override
  Future<List<MosquePlace>> findNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
    bool bypassCache = false,
  }) async {
    final key = _cacheKey(origin, radiusMeters);
    final now = _clock();
    _cache.removeWhere((_, value) => !now.isBefore(value.expiresAt));
    final cached = bypassCache ? null : _cache[key];
    if (cached != null) return _mapAndFilter(cached.places, origin);

    try {
      final data = await service.fetchPlaces(
        origin: origin,
        radiusMeters: radiusMeters,
      );
      final immutableData = List<MosquePlaceData>.unmodifiable(data);
      _cache[key] = _CachedPlaces(
        places: immutableData,
        expiresAt: now.add(cacheTtl),
      );
      return _mapAndFilter(immutableData, origin);
    } on OverpassServiceException catch (error) {
      throw MosqueSearchFailure(
        error.reason == OverpassFailureReason.serviceBusy
            ? MosqueSearchFailureType.serviceBusy
            : MosqueSearchFailureType.unavailable,
      );
    }
  }

  List<MosquePlace> _mapAndFilter(
    Iterable<MosquePlaceData> data,
    GeoCoordinate origin,
  ) {
    final places = <MosquePlace>[];
    for (final item in data) {
      final tags = item.tags;
      final isMuslimPlaceOfWorship =
          tags['amenity'] == 'place_of_worship' && tags['religion'] == 'muslim';
      final isMusalla =
          tags['place_of_worship'] == 'musalla' && tags['religion'] == 'muslim';
      if (!isMuslimPlaceOfWorship && !isMusalla) continue;
      places.add(mapper.map(item, origin));
    }
    return List.unmodifiable(places);
  }

  String _cacheKey(GeoCoordinate origin, int radiusMeters) {
    final latitudeBucket = (origin.latitude * coordinateBucketScale).round();
    final longitudeBucket = (origin.longitude * coordinateBucketScale).round();
    return '$latitudeBucket:$longitudeBucket:$radiusMeters';
  }
}

class _CachedPlaces {
  const _CachedPlaces({required this.places, required this.expiresAt});

  final List<MosquePlaceData> places;
  final DateTime expiresAt;
}
