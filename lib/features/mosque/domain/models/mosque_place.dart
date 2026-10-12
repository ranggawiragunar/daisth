import '../../../../core/location/domain/models/geo_coordinate.dart';
import 'mosque_place_type.dart';

class MosquePlace {
  const MosquePlace({
    required this.id,
    required this.name,
    required this.coordinate,
    required this.distanceMeters,
    required this.type,
    this.shortAddress,
  });

  final String id;
  final String name;
  final GeoCoordinate coordinate;
  final double distanceMeters;
  final MosquePlaceType type;
  final String? shortAddress;
}
