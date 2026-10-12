import '../../../../core/location/domain/models/geo_coordinate.dart';
import 'mosque_place.dart';

class NearbyMosqueResult {
  NearbyMosqueResult({
    required this.origin,
    required List<MosquePlace> places,
    required this.searchedRadiusMeters,
    required this.usedLastKnownLocation,
  }) : places = List.unmodifiable(places);

  final GeoCoordinate origin;
  final List<MosquePlace> places;
  final int searchedRadiusMeters;
  final bool usedLastKnownLocation;
}
