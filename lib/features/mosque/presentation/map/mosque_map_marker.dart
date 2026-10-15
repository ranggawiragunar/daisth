import '../../../../core/location/domain/models/geo_coordinate.dart';
import '../../domain/models/mosque_place.dart';
import '../../domain/models/mosque_place_type.dart';
import '../../domain/models/nearby_mosque_result.dart';

enum MosqueMapMarkerKind { currentLocation, mosque, mushola, other }

class MosqueMapMarker {
  const MosqueMapMarker({
    required this.id,
    required this.coordinate,
    required this.kind,
    this.place,
  });

  static const currentLocationId = 'daisth-current-location';

  final String id;
  final GeoCoordinate coordinate;
  final MosqueMapMarkerKind kind;
  final MosquePlace? place;

  bool get isCurrentLocation => kind == MosqueMapMarkerKind.currentLocation;

  static List<MosqueMapMarker> fromResult(NearbyMosqueResult result) {
    final markers = <MosqueMapMarker>[
      MosqueMapMarker(
        id: currentLocationId,
        coordinate: result.origin,
        kind: MosqueMapMarkerKind.currentLocation,
      ),
    ];
    final seenIds = <String>{currentLocationId};
    for (final place in result.places) {
      if (place.id.trim().isEmpty || !seenIds.add(place.id)) continue;
      markers.add(
        MosqueMapMarker(
          id: place.id,
          coordinate: place.coordinate,
          kind: switch (place.type) {
            MosquePlaceType.mosque => MosqueMapMarkerKind.mosque,
            MosquePlaceType.musalla => MosqueMapMarkerKind.mushola,
            MosquePlaceType.unknown => MosqueMapMarkerKind.other,
          },
          place: place,
        ),
      );
    }
    return List.unmodifiable(markers);
  }
}
