import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/maps/daisth_map_config.dart';
import 'package:daisth/features/mosque/domain/models/mosque_place.dart';
import 'package:daisth/features/mosque/domain/models/mosque_place_type.dart';
import 'package:daisth/features/mosque/domain/models/nearby_mosque_result.dart';
import 'package:daisth/features/mosque/presentation/map/mosque_map_coordinate_mapper.dart';
import 'package:daisth/features/mosque/presentation/map/mosque_map_marker.dart';

void main() {
  test('map themes select the verified OpenFreeMap styles', () {
    expect(
      DaisthMapConfig.styleUrlFor(isDark: false),
      'https://tiles.openfreemap.org/styles/liberty',
    );
    expect(
      DaisthMapConfig.styleUrlFor(isDark: true),
      'https://tiles.openfreemap.org/styles/dark',
    );
  });

  test('coordinate adapter preserves latitude and longitude order', () {
    const coordinate = GeoCoordinate(latitude: -6.2, longitude: 106.8);

    final mapCoordinate = MosqueMapCoordinateMapper.toMapLibre(coordinate);

    expect(mapCoordinate.latitude, -6.2);
    expect(mapCoordinate.longitude, closeTo(106.8, 1e-10));
    final geoJson = mapCoordinate.toGeoJsonCoordinates() as List<num>;
    expect(geoJson[0], closeTo(106.8, 1e-10));
    expect(geoJson[1], closeTo(-6.2, 1e-10));
    expect(
      MosqueMapCoordinateMapper.fromMapLibre(mapCoordinate).latitude,
      -6.2,
    );
    expect(
      MosqueMapCoordinateMapper.fromMapLibre(mapCoordinate).longitude,
      closeTo(106.8, 1e-10),
    );
  });

  test('current location and place markers retain their own coordinates', () {
    const origin = GeoCoordinate(latitude: -6.1754, longitude: 106.8272);
    const mosqueCoordinate = GeoCoordinate(
      latitude: -6.2001,
      longitude: 106.8453,
    );
    const musholaCoordinate = GeoCoordinate(
      latitude: -6.1556,
      longitude: 106.8127,
    );
    final result = NearbyMosqueResult(
      origin: origin,
      places: [
        _place(
          'node/101',
          'Masjid A',
          mosqueCoordinate,
          MosquePlaceType.mosque,
        ),
        _place(
          'node/202',
          'Mushola B',
          musholaCoordinate,
          MosquePlaceType.musalla,
        ),
      ],
      searchedRadiusMeters: 5000,
      usedLastKnownLocation: false,
    );

    final markers = MosqueMapMarker.fromResult(result);

    expect(markers.map((marker) => marker.id), [
      MosqueMapMarker.currentLocationId,
      'node/101',
      'node/202',
    ]);
    expect(markers.first.coordinate, origin);
    expect(markers[1].coordinate, mosqueCoordinate);
    expect(markers[1].kind, MosqueMapMarkerKind.mosque);
    expect(markers[2].coordinate, musholaCoordinate);
    expect(markers[2].kind, MosqueMapMarkerKind.mushola);
    expect(markers[1].place?.id, 'node/101');
    expect(markers[2].place?.id, 'node/202');
  });

  test('marker builder rejects duplicate or empty place identities', () {
    const origin = GeoCoordinate(latitude: -6.2, longitude: 106.8);
    const placeCoordinate = GeoCoordinate(latitude: -6.21, longitude: 106.81);
    final result = NearbyMosqueResult(
      origin: origin,
      places: [
        _place('node/101', 'Masjid A', placeCoordinate, MosquePlaceType.mosque),
        _place('node/101', 'Masjid duplicate', origin, MosquePlaceType.mosque),
        _place('', 'Masjid without identity', origin, MosquePlaceType.mosque),
        _place(
          MosqueMapMarker.currentLocationId,
          'Reserved identity',
          origin,
          MosquePlaceType.mosque,
        ),
      ],
      searchedRadiusMeters: 5000,
      usedLastKnownLocation: false,
    );

    final markers = MosqueMapMarker.fromResult(result);

    expect(markers.map((marker) => marker.id), [
      MosqueMapMarker.currentLocationId,
      'node/101',
    ]);
  });
}

MosquePlace _place(
  String id,
  String name,
  GeoCoordinate coordinate,
  MosquePlaceType type,
) => MosquePlace(
  id: id,
  name: name,
  coordinate: coordinate,
  distanceMeters: 150,
  type: type,
);
