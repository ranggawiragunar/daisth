import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:istiqam/core/location/domain/models/geo_coordinate.dart';
import 'package:istiqam/features/mosque/data/mappers/mosque_mapper.dart';
import 'package:istiqam/features/mosque/data/repositories/mosque_repository_data.dart';
import 'package:istiqam/features/mosque/data/services/mosque_overpass_service.dart';
import 'package:istiqam/features/mosque/domain/models/mosque_place_type.dart';
import 'package:istiqam/features/mosque/domain/models/mosque_search_failure.dart';

void main() {
  const origin = GeoCoordinate(latitude: -6.2, longitude: 106.8);

  test(
    'posts a local radius query and parses node/way/relation centers',
    () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'lat': -6.201,
                'lon': 106.8,
                'tags': {
                  'amenity': 'place_of_worship',
                  'religion': 'muslim',
                  'place_of_worship': 'mosque',
                },
              },
              {
                'type': 'way',
                'id': 2,
                'center': {'lat': -6.202, 'lon': 106.8},
                'tags': {
                  'amenity': 'place_of_worship',
                  'religion': 'muslim',
                  'place_of_worship': 'musalla',
                  'name': 'Musholla SMA Negeri 9 Jakarta',
                },
              },
              {
                'type': 'relation',
                'id': 3,
                'center': {'lat': -6.203, 'lon': 106.8},
                'tags': {
                  'amenity': 'place_of_worship',
                  'religion': 'muslim',
                  'place_of_worship': 'mosque',
                },
              },
              {
                'type': 'way',
                'id': 4,
                'tags': {'amenity': 'place_of_worship'},
              },
              {
                'type': 'node',
                'id': 1,
                'lat': -6.201,
                'lon': 106.8,
                'tags': {'amenity': 'place_of_worship', 'religion': 'muslim'},
              },
            ],
          }),
          200,
        );
      });
      final repository = MosqueRepositoryData(
        service: MosqueOverpassService(client: client),
        mapper: MosqueMapper(),
      );

      final places = await repository.findNearby(
        origin: origin,
        radiusMeters: 1500,
      );

      expect(captured!.url, MosqueOverpassService.endpoint);
      expect(captured!.method, 'POST');
      expect(captured!.headers['accept'], 'application/json');
      expect(
        Uri.splitQueryString(captured!.body)['data'],
        contains('nwr(around:1500,-6.2,106.8)'),
      );
      expect(places.map((place) => place.id), [
        'node/1',
        'way/2',
        'relation/3',
      ]);
      expect(places.first.distanceMeters, lessThan(places.last.distanceMeters));
      expect(places.first.type, MosquePlaceType.mosque);
      expect(places.first.name, 'Masjid');
      expect(places[1].type, MosquePlaceType.musalla);
      expect(places[1].name, 'Musholla SMA Negeri 9 Jakarta');
    },
  );

  test(
    'ignores non-Muslim worship data and maps server errors safely',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'lat': -6.201,
                'lon': 106.8,
                'tags': {
                  'amenity': 'place_of_worship',
                  'religion': 'christian',
                },
              },
            ],
          }),
          200,
        ),
      );
      final repository = MosqueRepositoryData(
        service: MosqueOverpassService(client: client),
        mapper: MosqueMapper(),
      );
      expect(
        await repository.findNearby(origin: origin, radiusMeters: 1500),
        isEmpty,
      );

      final busyRepository = MosqueRepositoryData(
        service: MosqueOverpassService(
          client: MockClient((_) async => http.Response('busy', 429)),
        ),
        mapper: MosqueMapper(),
      );
      await expectLater(
        busyRepository.findNearby(origin: origin, radiusMeters: 1500),
        throwsA(
          isA<MosqueSearchFailure>().having(
            (failure) => failure.type,
            'type',
            MosqueSearchFailureType.serviceBusy,
          ),
        ),
      );
    },
  );
}
