import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../models/mosque_place.dart';

abstract interface class MosqueRepository {
  Future<List<MosquePlace>> findNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
  });
}
