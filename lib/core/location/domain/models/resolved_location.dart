import 'geo_coordinate.dart';

class ResolvedLocation {
  const ResolvedLocation({
    required this.coordinate,
    required this.usedLastKnownLocation,
  });

  final GeoCoordinate coordinate;
  final bool usedLastKnownLocation;
}
