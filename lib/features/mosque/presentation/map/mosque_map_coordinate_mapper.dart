import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/location/domain/models/geo_coordinate.dart';

/// Converts Daisth's named latitude/longitude values to MapLibre's LatLng.
///
/// MapLibre's LatLng constructor also takes latitude first. GeoJSON is the
/// layer that serializes coordinates as longitude, latitude.
abstract final class MosqueMapCoordinateMapper {
  static LatLng toMapLibre(GeoCoordinate coordinate) =>
      LatLng(coordinate.latitude, coordinate.longitude);

  static GeoCoordinate fromMapLibre(LatLng coordinate) => GeoCoordinate(
    latitude: coordinate.latitude,
    longitude: coordinate.longitude,
  );
}
