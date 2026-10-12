import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../../domain/models/mosque_place.dart';
import '../../domain/models/mosque_search_failure.dart';
import '../../domain/repositories/mosque_repository.dart';
import '../mappers/mosque_mapper.dart';
import '../services/mosque_overpass_service.dart';

class MosqueRepositoryData implements MosqueRepository {
  const MosqueRepositoryData({required this.service, required this.mapper});

  final MosqueOverpassService service;
  final MosqueMapper mapper;

  @override
  Future<List<MosquePlace>> findNearby({
    required GeoCoordinate origin,
    required int radiusMeters,
  }) async {
    try {
      final data = await service.fetchPlaces(
        origin: origin,
        radiusMeters: radiusMeters,
      );
      final placesById = <String, MosquePlace>{};
      for (final item in data) {
        final tags = item.tags;
        final isMuslimPlaceOfWorship =
            tags['amenity'] == 'place_of_worship' &&
            tags['religion'] == 'muslim';
        final isMusalla =
            tags['place_of_worship'] == 'musalla' &&
            tags['religion'] == 'muslim';
        if (!isMuslimPlaceOfWorship && !isMusalla) continue;
        placesById.putIfAbsent(item.providerId, () => mapper.map(item, origin));
      }
      final places = placesById.values.toList()
        ..sort(
          (first, second) =>
              first.distanceMeters.compareTo(second.distanceMeters),
        );
      return List.unmodifiable(places);
    } on OverpassServiceException catch (error) {
      throw MosqueSearchFailure(
        error.reason == OverpassFailureReason.serviceBusy
            ? MosqueSearchFailureType.serviceBusy
            : MosqueSearchFailureType.unavailable,
      );
    }
  }
}
