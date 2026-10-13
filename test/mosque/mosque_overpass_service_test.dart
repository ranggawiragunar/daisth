import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/features/mosque/data/mappers/mosque_mapper.dart';
import 'package:daisth/features/mosque/data/repositories/mosque_repository_data.dart';
import 'package:daisth/features/mosque/data/services/mosque_overpass_service.dart';
import 'package:daisth/features/mosque/domain/models/mosque_place_type.dart';
import 'package:daisth/features/mosque/domain/models/mosque_search_failure.dart';

void main() {
  const origin = GeoCoordinate(latitude: -6.2, longitude: 106.8);

  test(
    'posts one local radius query and parses/deduplicates OSM elements',
    () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          _payload([
            _node(1, -6.201, 106.8, {
              'amenity': 'place_of_worship',
              'religion': 'muslim',
              'place_of_worship': 'mosque',
            }),
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
            _node(1, -6.201, 106.8, {
              'amenity': 'place_of_worship',
              'religion': 'muslim',
            }),
          ]),
          200,
        );
      });
      final repository = _repository(client);

      final places = await repository.findNearby(
        origin: origin,
        radiusMeters: 5000,
      );

      expect(captured!.url, MosqueOverpassService.primaryEndpoint);
      expect(captured!.method, 'POST');
      expect(captured!.headers['accept'], 'application/json');
      expect(
        Uri.splitQueryString(captured!.body)['data'],
        contains('nwr(around:5000,-6.2,106.8)'),
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

  test('uses fallback once after a retryable primary failure', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url == MosqueOverpassService.primaryEndpoint) {
        return http.Response('busy', 503);
      }
      return http.Response(_payload([]), 200);
    });
    final places = await _repository(
      client,
    ).findNearby(origin: origin, radiusMeters: 5000);

    expect(places, isEmpty);
    expect(requests, [
      MosqueOverpassService.primaryEndpoint,
      MosqueOverpassService.fallbackEndpoint,
    ]);
  });

  test('does not call fallback when primary succeeds', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response(_payload([]), 200);
    });

    expect(
      await _repository(client).findNearby(origin: origin, radiusMeters: 5000),
      isEmpty,
    );
    expect(requests, [MosqueOverpassService.primaryEndpoint]);
  });

  test('falls back once after a network error', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url == MosqueOverpassService.primaryEndpoint) {
        throw http.ClientException('network unavailable');
      }
      return http.Response(_payload([]), 200);
    });

    expect(
      await _repository(client).findNearby(origin: origin, radiusMeters: 5000),
      isEmpty,
    );
    expect(requests, [
      MosqueOverpassService.primaryEndpoint,
      MosqueOverpassService.fallbackEndpoint,
    ]);
  });

  test('falls back once after a primary timeout', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url == MosqueOverpassService.primaryEndpoint) {
        return Completer<http.Response>().future;
      }
      return http.Response(_payload([]), 200);
    });
    final service = MosqueOverpassService(
      client: client,
      requestTimeout: const Duration(milliseconds: 1),
    );

    expect(
      await service.fetchPlaces(origin: origin, radiusMeters: 5000),
      isEmpty,
    );
    expect(requests, [
      MosqueOverpassService.primaryEndpoint,
      MosqueOverpassService.fallbackEndpoint,
    ]);
  });

  test('does not retry or fall back for a client request error', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response('bad request', 400);
    });

    await expectLater(
      _repository(client).findNearby(origin: origin, radiusMeters: 5000),
      throwsA(isA<MosqueSearchFailure>()),
    );
    expect(requests, [MosqueOverpassService.primaryEndpoint]);
  });

  test('reports provider failure when both endpoints fail', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response('busy', 429);
    });
    final repository = _repository(client);

    await expectLater(
      repository.findNearby(origin: origin, radiusMeters: 5000),
      throwsA(
        isA<MosqueSearchFailure>().having(
          (failure) => failure.type,
          'type',
          MosqueSearchFailureType.serviceBusy,
        ),
      ),
    );
    expect(requests, [
      MosqueOverpassService.primaryEndpoint,
      MosqueOverpassService.fallbackEndpoint,
    ]);
  });

  test(
    'caches raw results for five minutes by rounded coordinate bucket',
    () async {
      var now = DateTime(2026, 1, 1);
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(
          _payload([_node(1, -6.201, 106.8, _muslimMosqueTags)]),
          200,
        );
      });
      final repository = _repository(client, clock: () => now);
      const nearbyOrigin = GeoCoordinate(
        latitude: -6.2001,
        longitude: 106.8001,
      );

      final first = await repository.findNearby(
        origin: origin,
        radiusMeters: 5000,
      );
      final nearby = await repository.findNearby(
        origin: nearbyOrigin,
        radiusMeters: 5000,
      );
      expect(requests, 1);
      expect(first.single.distanceMeters, isNot(nearby.single.distanceMeters));

      await repository.findNearby(
        origin: nearbyOrigin,
        radiusMeters: 5000,
        bypassCache: true,
      );
      expect(requests, 2);

      now = now.add(const Duration(minutes: 5, seconds: 1));
      final stale = await repository.getCachedNearby(
        origin: origin,
        radiusMeters: 5000,
      );
      expect(stale, isNotNull);
      expect(stale!.isFresh, isFalse);
      expect(stale.places, hasLength(1));
      await repository.findNearby(origin: origin, radiusMeters: 5000);
      expect(requests, 3);
    },
  );

  test('empty refresh does not replace a same-area non-empty cache', () async {
    var responseIndex = 0;
    final client = MockClient((_) async {
      responseIndex++;
      return http.Response(
        responseIndex == 1
            ? _payload([_node(1, -6.201, 106.8, _muslimMosqueTags)])
            : _payload([]),
        200,
      );
    });
    final repository = _repository(client);

    final first = await repository.findNearby(
      origin: origin,
      radiusMeters: 5000,
    );
    final refreshed = await repository.findNearby(
      origin: origin,
      radiusMeters: 5000,
      bypassCache: true,
    );
    final retained = await repository.getCachedNearby(
      origin: origin,
      radiusMeters: 5000,
    );

    expect(first, hasLength(1));
    expect(refreshed, isEmpty);
    expect(retained!.places.map((place) => place.id), ['node/1']);
  });

  test(
    'a different coordinate bucket cannot read another area cache',
    () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(
            _payload([_node(1, -6.201, 106.8, _muslimMosqueTags)]),
            200,
          );
        }
        return http.Response('busy', 503);
      });
      final repository = _repository(client);
      await repository.findNearby(origin: origin, radiusMeters: 5000);
      const otherArea = GeoCoordinate(latitude: -6.3, longitude: 106.8);

      expect(
        await repository.getCachedNearby(origin: otherArea, radiusMeters: 5000),
        isNull,
      );
      await expectLater(
        repository.findNearby(origin: otherArea, radiusMeters: 5000),
        throwsA(isA<MosqueSearchFailure>()),
      );
    },
  );

  test(
    'a different area can return empty without exposing the old cache',
    () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response(
          requestCount == 1
              ? _payload([_node(1, -6.201, 106.8, _muslimMosqueTags)])
              : _payload([]),
          200,
        );
      });
      final repository = _repository(client);
      final original = await repository.findNearby(
        origin: origin,
        radiusMeters: 5000,
      );
      const otherArea = GeoCoordinate(latitude: -6.3, longitude: 106.8);

      final otherAreaResult = await repository.findNearby(
        origin: otherArea,
        radiusMeters: 5000,
      );

      expect(original, hasLength(1));
      expect(otherAreaResult, isEmpty);
      expect(
        await repository.getCachedNearby(origin: otherArea, radiusMeters: 5000),
        isNotNull,
      );
      expect(
        (await repository.getCachedNearby(
          origin: origin,
          radiusMeters: 5000,
        ))!.places,
        hasLength(1),
      );
    },
  );

  test(
    'stale cache is retained after provider failure and refreshed on success',
    () async {
      var now = DateTime(2026, 1, 1);
      var responseIndex = 0;
      final client = MockClient((_) async {
        responseIndex++;
        if (responseIndex == 1) {
          return http.Response(
            _payload([_node(1, -6.201, 106.8, _muslimMosqueTags)]),
            200,
          );
        }
        if (responseIndex <= 3) return http.Response('busy', 503);
        return http.Response(
          _payload([_node(2, -6.202, 106.8, _muslimMosqueTags)]),
          200,
        );
      });
      final repository = _repository(client, clock: () => now);
      await repository.findNearby(origin: origin, radiusMeters: 5000);
      now = now.add(const Duration(minutes: 6));

      await expectLater(
        repository.findNearby(
          origin: origin,
          radiusMeters: 5000,
          bypassCache: true,
        ),
        throwsA(isA<MosqueSearchFailure>()),
      );
      expect(
        (await repository.getCachedNearby(
          origin: origin,
          radiusMeters: 5000,
        ))!.places.map((place) => place.id),
        ['node/1'],
      );

      final fresh = await repository.findNearby(
        origin: origin,
        radiusMeters: 5000,
        bypassCache: true,
      );
      final replaced = await repository.getCachedNearby(
        origin: origin,
        radiusMeters: 5000,
      );
      expect(fresh.map((place) => place.id), ['node/2']);
      expect(replaced!.places.map((place) => place.id), ['node/2']);
      expect(replaced.isFresh, isTrue);
    },
  );
}

MosqueRepositoryData _repository(
  http.Client client, {
  DateTime Function()? clock,
}) => MosqueRepositoryData(
  service: MosqueOverpassService(client: client),
  mapper: MosqueMapper(),
  clock: clock,
);

const _muslimMosqueTags = {
  'amenity': 'place_of_worship',
  'religion': 'muslim',
  'place_of_worship': 'mosque',
};

Map<String, Object> _node(
  int id,
  double latitude,
  double longitude,
  Map<String, String> tags,
) => {
  'type': 'node',
  'id': id,
  'lat': latitude,
  'lon': longitude,
  'tags': tags,
};

String _payload(List<Map<String, Object>> elements) =>
    jsonEncode({'elements': elements});
