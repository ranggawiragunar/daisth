import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../models/cached_mosque_places.dart';
import '../models/mosque_place.dart';

abstract interface class MosqueRepository {
  Future<CachedMosquePlaces?> getCachedNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
  });

  Future<List<MosquePlace>> findNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
    bool bypassCache = false,
  });
}
